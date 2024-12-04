const std = @import("std");
const utils = @import("utils.zig");

const Pos = struct {
    x: isize,
    y: isize,

    pub fn add(self: Pos, rhs: Pos) Pos {
        return Pos{
            .x = self.x + rhs.x,
            .y = self.y + rhs.y,
        };
    }

    pub fn sub(self: Pos, rhs: Pos) Pos {
        return Pos{
            .x = self.x - rhs.x,
            .y = self.y - rhs.y,
        };
    }

    pub fn format(
        self: Pos,
        comptime _: []const u8,
        _: anytype,
        writer: anytype,
    ) !void {
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

const WordSearch = struct {
    input: []const u8,
    width: isize,
    height: isize,

    pub fn new(input: []const u8) WordSearch {
        const height = utils.countLines(input);

        var lines = std.mem.split(u8, input, "\n");
        const first_line = lines.next().?;
        const width = first_line.len;

        return WordSearch{
            .input = input,
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn at(self: WordSearch, pos: Pos) u8 {
        return self.input[@intCast((self.width + 1) * pos.y + pos.x)];
    }

    pub fn inBounds(self: WordSearch, pos: Pos) bool {
        if (pos.x < 0 or pos.y < 0) {
            return false;
        }

        if (pos.x >= self.width or pos.y >= self.height) {
            return false;
        }

        return true;
    }

    pub fn lookForAdjecent(
        self: *const WordSearch,
        base: Pos,
        needle: u8,
    ) AdjecentIter {
        return AdjecentIter{
            .base = base,
            .needle = needle,
            .search = self,
        };
    }

    const AdjecentIter = struct {
        base: Pos,
        search: *const WordSearch,
        needle: u8,
        offset: usize = 0,

        pub fn next(self: *AdjecentIter) ?Pos {
            const offsets: []const Pos = &.{
                Pos{ .x = -1, .y = -1 },
                Pos{ .x = 0, .y = -1 },
                Pos{ .x = 1, .y = -1 },

                Pos{ .x = -1, .y = 0 },
                Pos{ .x = 1, .y = 0 },

                Pos{ .x = -1, .y = 1 },
                Pos{ .x = 0, .y = 1 },
                Pos{ .x = 1, .y = 1 },
            };

            while (self.offset < offsets.len) {
                defer self.offset += 1;

                const check_at = self.base.add(offsets[self.offset]);
                if (!self.search.inBounds(check_at)) continue;

                if (self.search.at(check_at) == self.needle) {
                    return check_at;
                }
            }

            return null;
        }
    };
};

pub fn isLegal(positions: []const Pos) bool {
    var prev: ?Pos = null;
    for (1..positions.len) |i| {
        const cur = positions[i].sub(positions[i - 1]);

        if (prev) |p| {
            if (p.x != cur.x or p.y != cur.y) {
                return false;
            }
        }
        prev = cur;
    }

    if (prev.?.x == 0 or prev.?.y == 0) {
        return false;
    }

    return true;
}

pub fn main() !void {
    const input = try utils.readInput();
    const search = WordSearch.new(input);

    var centers = std.ArrayHashMap(Pos, u32, (struct {
        pub fn eql(_: @This(), a: Pos, b: Pos, _: anytype) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub fn hash(_: @This(), a: Pos) u32 {
            var buf: [32]u8 = undefined;
            const text = std.fmt.bufPrint(&buf, "{}", .{a}) catch unreachable;
            return std.hash.Adler32.hash(text);
        }
    }), false).init(utils.alloc);

    for (0..@intCast(search.height)) |y| {
        for (0..@intCast(search.width)) |x| {
            const M = Pos{ .x = @intCast(x), .y = @intCast(y) };
            if (search.at(M) != 'M') continue;

            var a_iter = search.lookForAdjecent(M, 'A');
            while (a_iter.next()) |A| {
                var s_iter = search.lookForAdjecent(A, 'S');
                while (s_iter.next()) |S| {
                    if (isLegal(&.{ M, A, S })) {
                        const entry = try centers.getOrPut(A);
                        if (entry.found_existing) {
                            entry.value_ptr.* += 1;
                        } else {
                            entry.value_ptr.* = 1;
                        }
                    }
                }
            }
        }
    }

    var n: usize = 0;

    var iter = centers.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* > 1) {
            n += 1;
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{n});
}
