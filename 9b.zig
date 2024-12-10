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

const File = struct {
    start_pos: usize,
    len: usize,
    id: u16,
};

const FileIter = struct {
    blocks: []?u16,
    pos: usize,

    pub fn init(blocks: []?u16) FileIter {
        return FileIter{
            .blocks = blocks,
            .pos = blocks.len - 1,
        };
    }

    pub fn next(self: *FileIter) ?File {
        while (self.pos > 1 and self.blocks[self.pos] == null) {
            self.pos -= 1;
        }
        if (self.pos == 0) return null;

        const end_inclusive = self.pos;

        const id = self.blocks[self.pos].?;

        var len: usize = 0;
        while (self.blocks[self.pos] == id) {
            len += 1;

            if (self.pos == 0) {
                break;
            } else {
                self.pos -= 1;
            }
        }

        return File{
            .start_pos = (end_inclusive + 1) - len,
            .len = len,
            .id = id,
        };
    }
};

const Space = struct {
    start: usize,
    len: usize,
};

const SpaceIter = struct {
    blocks: []?u16,
    pos: usize,

    pub fn init(blocks: []?u16) SpaceIter {
        return SpaceIter{
            .blocks = blocks,
            .pos = 0,
        };
    }

    pub fn next(self: *SpaceIter) ?Space {
        const next_free = std.mem.indexOfScalarPos(
            ?u16,
            self.blocks,
            self.pos,
            null,
        ) orelse return null;

        self.pos = next_free;
        var len: usize = 0;
        while (self.pos < self.blocks.len and self.blocks[self.pos] == null) {
            len += 1;
            self.pos += 1;
        }

        return Space{
            .start = next_free,
            .len = len,
        };
    }
};

pub fn defragment(blocks: []?u16) void {
    var files = FileIter.init(blocks);
    while (files.next()) |file| {
        var spaces = SpaceIter.init(blocks);
        while (spaces.next()) |space| {
            if (space.len >= file.len and space.start < file.start_pos) {
                for (0..file.len) |i| {
                    blocks[space.start + i] = blocks[file.start_pos + i];
                    blocks[file.start_pos + i] = null;
                }

                break;
            }
        }
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
