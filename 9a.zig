const std = @import("std");
const utils = @import("./utils.zig");

pub fn parseBlocks(input: []const u8) ![]?u16 {
    var id: u16 = 0;
    var blocks = try std.ArrayList(?u16).initCapacity(utils.alloc, input.len * 10);
    var pos: usize = 0;

    while (pos < input.len) : (pos += 2) {
        if (input[pos] == '\n') break;
        const n_blocks: u8 = input[pos] - '0';
        blocks.appendNTimesAssumeCapacity(id, n_blocks);

        id += 1;

        if (input[pos + 1] == '\n') break;
        const n_free: u8 = input[pos + 1] - '0';
        blocks.appendNTimesAssumeCapacity(null, n_free);
    }

    return blocks.items;
}

pub fn defragment(blocks: []?u16) void {
    var top: usize = blocks.len - 1;
    var next_free: usize = std.mem.indexOfScalarPos(
        ?u16,
        blocks,
        0,
        null,
    ) orelse return;

    while (top >= next_free) : (top -= 1) {
        if (blocks[top] == null) continue;

        std.mem.swap(?u16, &blocks[top], &blocks[next_free]);

        next_free = std.mem.indexOfScalarPos(
            ?u16,
            blocks,
            next_free + 1,
            null,
        ) orelse return;
    }
}

pub fn printBlocks(blocks: []const ?u16) !void {
    const writer = std.io.getStdErr().writer();

    for (blocks) |block| {
        if (block) |id| {
            try writer.print("{d}", .{id});
        } else {
            try writer.print(".", .{});
        }
    }

    try writer.print("\n", .{});
}

pub fn checksum(blocks: []const ?u16) u64 {
    var sum: u64 = 0;

    for (blocks, 0..) |block, i| {
        if (block) |id| {
            sum += @as(u64, @intCast(id)) * @as(u64, @intCast(i));
        }
    }

    return sum;
}

pub fn main() !void {
    const input = try utils.readInput();
    const blocks = try parseBlocks(input);

    try printBlocks(blocks);
    defragment(blocks);
    try printBlocks(blocks);

    try std.io.getStdOut().writer().print(
        "{d}\n",
        .{checksum(blocks)},
    );
}
