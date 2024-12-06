const std = @import("std");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const alloc = arena.allocator();

pub threadlocal var tlarena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub fn countLines(input: []const u8) usize {
    var lines = std.mem.split(u8, input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| {
        if (line.len > 0) {
            i += 1;
        }
    }
    return i;
}

pub fn readInput() ![]const u8 {
    return try std.io.getStdIn().reader().readAllAlloc(
        alloc,
        1024 * 1024 * 1024,
    );
}
