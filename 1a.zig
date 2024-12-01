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

pub fn main() !void {
    const input = try utils.readInput();

    const parsed = try parse(input);

    const cmp = struct {
        pub fn cmp(_: void, a: u32, b: u32) bool {
            return a < b;
        }
    }.cmp;

    std.mem.sort(u32, parsed.a, {}, cmp);
    std.mem.sort(u32, parsed.b, {}, cmp);

    std.log.debug("parsed = {any}", .{parsed});

    var dist_sum: u64 = 0;
    for (parsed.a, parsed.b) |a, b| {
        dist_sum += @as(u64, @abs(@as(i64, @intCast(a)) - @as(i64, @intCast(b))));
    }

    try std.io.getStdOut().writer().print("{d}\n", .{dist_sum});
}
