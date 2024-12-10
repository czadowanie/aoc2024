const std = @import("std");
const utils = @import("utils.zig");

const Vec2 = @Vector(2, isize);

pub const Map = struct {
    input: []const u8,
    width: usize,
    height: usize,

    pub fn parse(input: []const u8) Map {
        const height = utils.countLines(input);
        const stride = input.len / height;

        return Map{
            .input = input,
            .width = stride - 1,
            .height = height,
        };
    }

    pub fn get(self: Map, x: anytype, y: anytype) ?u8 {
        if (x < 0) return null;
        if (@as(usize, @intCast(x)) >= self.width) return null;
        if (y < 0) return null;
        if (@as(usize, @intCast(y)) >= self.height) return null;

        const stride = self.width + 1;
        return self.input[
            (stride * @as(usize, @intCast(y))) +
                @as(usize, @intCast(x))
        ] - '0';
    }

    pub fn pathsAt(self: *const Map, x: anytype, y: anytype) PossiblePaths {
        return PossiblePaths{
            .map = self,
            .pos = Vec2{ x, y },
            .tried = 0,
        };
    }
};

pub const PossiblePaths = struct {
    map: *const Map,
    pos: Vec2,
    tried: usize,

    pub fn next(self: *PossiblePaths) ?Vec2 {
        const dirs = [4]Vec2{
            Vec2{ 0, -1 },
            Vec2{ 1, 0 },
            Vec2{ 0, 1 },
            Vec2{ -1, 0 },
        };

        while (self.tried < dirs.len) {
            defer self.tried += 1;

            const new_pos = self.pos + dirs[self.tried];

            const cur = self.map.get(self.pos[0], self.pos[1]).?;
            const new = self.map.get(new_pos[0], new_pos[1]) orelse continue;

            if (cur + 1 == new) {
                return new_pos;
            }
        }

        return null;
    }
};

const NineSet = std.AutoArrayHashMap(Vec2, void);

pub fn search(map: *const Map, pos: Vec2, nines: *NineSet) !void {
    if (map.get(pos[0], pos[1]) == 9) {
        try nines.put(pos, {});
    } else {
        var paths = map.pathsAt(pos[0], pos[1]);
        while (paths.next()) |next| {
            try search(map, next, nines);
        }
    }
}

pub fn main() !void {
    const input = try utils.readInput();
    const map = Map.parse(input);

    const stderr = std.io.getStdErr().writer();

    for (0..map.height) |y| {
        for (0..map.width) |x| {
            try stderr.print("{?d}", .{map.get(x, y)});
        }
        try stderr.print("\n", .{});
    }

    var nines = NineSet.init(utils.alloc);
    var sum: usize = 0;
    for (0..map.height) |y| {
        for (0..map.width) |x| {
            if (map.get(x, y) == 0) {
                try search(&map, Vec2{ @intCast(x), @intCast(y) }, &nines);

                std.log.debug("({d}, {d}) -> {d}", .{ x, y, nines.count() });
                sum += nines.count();

                nines.clearRetainingCapacity();
            }
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
