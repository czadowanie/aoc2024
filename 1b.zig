const std = @import("std");
const utils = @import("./utils.zig");

const Output = struct {
    a: []u32,
    b: []u32,
};

fn parse(input: []const u8) !Output {
    const len: usize = blk: {
        var lines = std.mem.split(u8, input, "\n");
        var i: usize = 0;
        while (lines.next()) |line| {
            if (line.len > 0) {
                i += 1;
            }
        }
        break :blk i;
    };

    const a = try utils.alloc.alloc(u32, len);
    const b = try utils.alloc.alloc(u32, len);

    var lines = std.mem.split(u8, input, "\n");

    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        if (line.len == 0) {
            continue;
        }

        var items = std.mem.split(u8, line, " ");

        std.log.debug("line = '{s}'", .{line});
        const item_a = items.next().?;
        _ = items.next().?;
        _ = items.next().?;
        const item_b = items.next().?;
        std.log.debug("item_a = '{s}'", .{item_a});
        std.log.debug("item_b = '{s}'", .{item_b});

        a[i] = try std.fmt.parseInt(u32, item_a, 10);
        b[i] = try std.fmt.parseInt(u32, item_b, 10);
    }

    return .{
        .a = a,
        .b = b,
    };
}

pub fn findIndex(list: []const u32, start: usize, end: usize, n: u32) ?usize {
    const midpoint = start + ((end - start) / 2);

    if (end - start == 0) {
        return null;
    } else if (end - start == 1) {
        if (list[start] == n) {
            return start;
        } else {
            return null;
        }
    }

    if (list[midpoint] > n) {
        return findIndex(list, start, midpoint, n);
    } else if (list[midpoint] < n) {
        return findIndex(list, midpoint, end, n);
    } else {
        return midpoint;
    }
}

pub fn dedup(list: []const u32) !Output {
    var nums = try std.ArrayList(u32).initCapacity(utils.alloc, list.len);
    var occurences = try std.ArrayList(u32).initCapacity(utils.alloc, list.len);

    var pos: usize = 0;
    while (pos < list.len) {
        const n = list[pos];

        var occ: u32 = 0;
        for (list[pos..]) |el| {
            if (el == n) {
                occ += 1;
            } else {
                break;
            }
        }

        nums.appendAssumeCapacity(n);
        occurences.appendAssumeCapacity(occ);

        pos += @intCast(occ);
    }

    return Output{
        .a = nums.items,
        .b = occurences.items,
    };
}

pub fn findOccurences(nums: []const u32, occs: []const u32, n: u32) u32 {
    const index = findIndex(
        nums,
        0,
        nums.len,
        n,
    ) orelse return 0;
    return occs[index];
}

pub fn main() !void {
    const input = try utils.readInput();

    const parsed = try parse(input);

    const cmp = struct {
        pub fn cmp(_: void, a: u32, b: u32) bool {
            return a < b;
        }
    }.cmp;

    std.mem.sort(u32, parsed.b, {}, cmp);

    std.log.debug("parsed = {any}", .{parsed});

    var dist_sum: u64 = 0;
    for (parsed.a, parsed.b) |a, b| {
        dist_sum += @as(u64, @abs(@as(i64, @intCast(a)) - @as(i64, @intCast(b))));
    }

    const deduped = try dedup(parsed.b);
    std.log.debug("deduped = {any}", .{deduped});

    var score: u64 = 0;
    for (parsed.a) |n| {
        score += n * findOccurences(deduped.a, deduped.b, n);
    }

    try std.io.getStdOut().writer().print("{d}\n", .{score});
}
