const std = @import("std");
const utils = @import("utils.zig");

fn ndigits(n: u64) u64 {
    var n_copy = n;
    var n_digits: u64 = 0;
    while (n_copy != 0) : (n_digits += 1) {
        n_copy /= 10;
    }
    return n_digits;
}

fn split(n: u64, digits: u64) std.meta.Tuple(&.{ u64, u64 }) {
    var right: u64 = 0;
    var div: u64 = 10;
    for (0..digits / 2) |_| {
        right += (n % div) - right;
        div *= 10;
    }

    const left = (n - right) / std.math.pow(u64, 10, digits / 2);

    return .{ left, right };
}

pub fn blink(cells: *std.ArrayList(u64), n: u32) !u128 {
    var total: u128 = 0;

    var cache = std.AutoHashMap(Key, u64).init(utils.alloc);

    for (cells.items) |root| {
        total += try blinkOn(&cache, root, n);
    }

    return total;
}

const Key = struct { n: u64, depth: u32 };

pub fn blinkOn(cache: *std.AutoHashMap(Key, u64), n: u64, depth: u32) !u64 {
    if (depth == 0) return 1;

    const key = Key{ .n = n, .depth = depth };
    if (cache.get(key)) |v| return v;

    const value = if (n == 0)
        try blinkOn(cache, 1, depth - 1)
    else if (ndigits(n) & 0x1 == 0) blk: {
        const left, const right = split(n, ndigits(n));
        break :blk try blinkOn(cache, left, depth - 1) + try blinkOn(cache, right, depth - 1);
    } else try blinkOn(cache, n * 2024, depth - 1);

    try cache.putNoClobber(key, value);

    return value;
}

pub fn main() !void {
    const input = try utils.readInput();

    var cells = std.ArrayList(u64).init(utils.alloc);

    var txts = std.mem.splitAny(u8, input, " \n");
    while (txts.next()) |txt| {
        if (txt.len == 0) break;

        std.log.debug("txt = '{s}'", .{txt});
        try cells.append(try std.fmt.parseInt(u64, txt, 10));
    }

    std.log.debug("init state:\n{d}", .{cells.items});

    const sum = try blink(&cells, 75);

    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
