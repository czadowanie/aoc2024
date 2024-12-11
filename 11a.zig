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

pub fn blink(cells: *std.ArrayList(u64)) !void {
    const old = try cells.allocator.dupe(u64, cells.items);
    defer cells.allocator.free(old);

    cells.clearRetainingCapacity();
    for (old) |n| {
        if (n == 0) {
            try cells.append(1);
        } else if (ndigits(n) % 2 == 0) {
            var buf: [32]u8 = undefined;
            const txt = std.fmt.bufPrint(&buf, "{d}", .{n}) catch unreachable;
            const left_txt = txt[0 .. txt.len / 2];
            const right_txt = txt[txt.len / 2 ..];
            try cells.append(std.fmt.parseInt(u64, left_txt, 10) catch unreachable);
            try cells.append(std.fmt.parseInt(u64, right_txt, 10) catch unreachable);
        } else {
            try cells.append(n * 2024);
        }
    }
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

    for (0..25) |i| {
        try blink(&cells);
        std.log.debug(
            "blink {d}:\n{d}\nn_items = {d}\n",
            .{ i, cells.items, cells.items.len },
        );
    }

    try std.io.getStdOut().writer().print("{d}\n", .{cells.items.len});
}
