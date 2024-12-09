const std = @import("std");
const utils = @import("utils.zig");

pub const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(lhs: Vec2, rhs: Vec2) Vec2 {
        return vec2(lhs.x + rhs.x, lhs.y + rhs.y);
    }

    pub fn sub(lhs: Vec2, rhs: Vec2) Vec2 {
        return vec2(lhs.x - rhs.x, lhs.y - rhs.y);
    }

    pub fn eql(lhs: Vec2, rhs: Vec2) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }

    pub fn format(
        self: Vec2,
        _: anytype,
        _: anytype,
        writer: anytype,
    ) !void {
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

pub fn antinodeLocation(a: Vec2, b: Vec2) Vec2 {
    const delta = a.sub(b);
    return a.add(delta);
}

pub fn vec2(x: i32, y: i32) Vec2 {
    return Vec2{ .x = x, .y = y };
}

const max_antenna_freqs = ('z' - '0') + 1;

pub const Map = struct {
    size: Vec2,
    antennas: *[max_antenna_freqs]std.ArrayList(Vec2),

    pub fn contains(self: Map, point: Vec2) bool {
        if (point.x < 0 or point.y < 0) return false;
        if (point.x >= self.size.x or point.y >= self.size.y) return false;
        return true;
    }

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Map {
        var lines = std.mem.splitScalar(u8, input, '\n');

        const antennas = try allocator.create([max_antenna_freqs]std.ArrayList(Vec2));
        for (antennas[0..]) |*antenna| {
            antenna.* = std.ArrayList(Vec2).init(allocator);
        }

        var height: i32 = 0;
        var width: i32 = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;

            width = 0;

            for (line) |c| {
                if (c != '.') {
                    try antennas[c - '0'].append(vec2(height, width));
                }

                width += 1;
            }

            height += 1;
        }

        return Map{
            .size = vec2(width, height),
            .antennas = antennas,
        };
    }
};

pub fn main() !void {
    std.log.debug("max antenna freqs = {d}", .{max_antenna_freqs});

    const input = try utils.readInput();
    const map = try Map.parse(utils.alloc, input);

    std.log.debug("size = {}", .{map.size});

    var antinodes = std.AutoArrayHashMap(Vec2, void).init(utils.alloc);

    for (map.antennas) |antennas| {
        for (antennas.items) |a| {
            for (antennas.items) |b| {
                if (a.eql(b)) continue;

                const anti_a = antinodeLocation(a, b);
                if (map.contains(anti_a)) try antinodes.put(anti_a, {});

                const anti_b = antinodeLocation(b, a);
                if (map.contains(anti_b)) try antinodes.put(anti_b, {});

                std.log.debug("{}, {} -> {?}, {?}", .{
                    a,
                    b,
                    if (map.contains(anti_a)) anti_a else null,
                    if (map.contains(anti_b)) anti_b else null,
                });
            }
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{antinodes.count()});
}
