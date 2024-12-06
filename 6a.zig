const std = @import("std");
const utils = @import("utils.zig");
const Tuple = std.meta.Tuple;

pub const Cell = enum {
    space,
    obstacle,
};

pub const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x + b.x,
            .y = a.y + b.y,
        };
    }
};

pub fn vec2(x: i32, y: i32) Vec2 {
    return Vec2{ .x = x, .y = y };
}

pub const Map = struct {
    width: i32,
    height: i32,
    data: []const Cell,

    pub fn parse(input: []const u8) !Tuple(&.{ Map, Guard }) {
        var data = try std.ArrayList(Cell).initCapacity(utils.alloc, 128 * 128);

        var lines = std.mem.splitScalar(u8, input, '\n');
        var y: i32 = 0;

        var guard: ?Guard = null;

        while (lines.next()) |line| {
            var x: i32 = 0;
            if (line.len == 0) continue;

            for (line) |c| {
                switch (c) {
                    '.' => try data.append(Cell.space),
                    '#' => try data.append(Cell.obstacle),
                    '^', 'v', '<', '>' => {
                        guard = Guard{
                            .pos = vec2(x, y),
                            .dir = Guard.dirFromChar(c),
                        };
                        try data.append(Cell.space);
                    },
                    else => std.debug.panic("invalid map char {c}", .{c}),
                }

                x += 1;
            }

            y += 1;
        }

        return .{
            Map{
                .height = y,
                .width = @divFloor(@as(i32, @intCast(data.items.len)), y),
                .data = data.items,
            },
            (guard orelse return error.NoGuard),
        };
    }

    pub inline fn get(self: Map, x: anytype, y: anytype) ?Cell {
        const posx = @as(i32, @intCast(x));
        const posy = @as(i32, @intCast(y));

        if (posx < 0 or posx >= self.width) return null;
        if (posy < 0 or posy >= self.height) return null;

        return self.data[@intCast((posy * self.width) + posx)];
    }

    pub fn dump(self: Map, guard: Guard) !void {
        const writer = std.io.getStdErr().writer();

        for (0..@intCast(self.height)) |y| {
            for (0..@intCast(self.width)) |x| {
                const cell = self.get(x, y).?;

                const char: u8 = if (x == guard.pos.x and y == guard.pos.y)
                    guard.getChar()
                else switch (cell) {
                    .space => '.',
                    .obstacle => '#',
                };

                try writer.print("{c}", .{char});
            }

            try writer.print("\n", .{});
        }
    }
};

pub const Guard = struct {
    pos: Vec2,
    dir: Vec2,

    pub fn getChar(self: Guard) u8 {
        return switch (self.dir.x) {
            -1 => '<',
            1 => '>',
            0 => switch (self.dir.y) {
                -1 => '^',
                1 => 'v',
                else => @panic("invalid y dir"),
            },
            else => @panic("invalid x dir"),
        };
    }

    pub fn dirFromChar(c: u8) Vec2 {
        return switch (c) {
            '<' => vec2(-1, 0),
            '>' => vec2(1, 0),
            '^' => vec2(0, -1),
            'v' => vec2(0, 1),
            else => std.debug.panic("invalid dir char {c}", .{c}),
        };
    }

    fn turn(dir: Vec2) Vec2 {
        return switch (dir.x) {
            -1 => vec2(0, -1),
            1 => vec2(0, 1),
            0 => switch (dir.y) {
                -1 => vec2(1, 0),
                1 => vec2(-1, 0),
                else => @panic("invalid y dir"),
            },
            else => @panic("invalid x dir"),
        };
    }

    pub fn step(self: Guard, map: Map) ?Guard {
        const new_pos = self.pos.add(self.dir);
        const new_cell = map.get(new_pos.x, new_pos.y) orelse return null;

        if (new_cell == .space) {
            return Guard{
                .pos = new_pos,
                .dir = self.dir,
            };
        } else if (new_cell == .obstacle) {
            return Guard{
                .pos = self.pos,
                .dir = turn(self.dir),
            };
        }

        unreachable;
    }
};

pub fn main() !void {
    const input = try utils.readInput();
    const map, var guard = try Map.parse(input);

    var positions = std.AutoArrayHashMap(Vec2, void).init(utils.alloc);
    try positions.put(guard.pos, {});

    try map.dump(guard);
    while (guard.step(map)) |new_guard| {
        guard = new_guard;
        try positions.put(guard.pos, {});
    }

    try std.io.getStdOut().writer().print("{d}\n", .{positions.count()});
}
