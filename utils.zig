const std = @import("std");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const alloc = arena.allocator();

pub fn readInput() ![]const u8 {
    return try std.io.getStdIn().reader().readAllAlloc(
        alloc,
        1024 * 1024 * 1024,
    );
}
