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

    pub fn eql(a: Vec2, b: Vec2) bool {
        return a.x == b.x and a.y == b.y;
    }
};

pub fn vec2(x: i32, y: i32) Vec2 {
    return Vec2{ .x = x, .y = y };
}

pub const Map = struct {
    width: i32,
    height: i32,
    data: []const Cell,
    additional_obstacle: ?Vec2 = null,

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

        if (self.additional_obstacle) |obstacle| {
            if (posx == obstacle.x and posy == obstacle.y) return .obstacle;
        }

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
        } else {
            std.debug.panic("unknown cell type", .{});
        }
    }
};

pub fn checkForLoop(map: Map, start: Guard, obstacle: Vec2) !bool {
    var visited = std.AutoArrayHashMap(Guard, void).init(utils.tlarena.allocator());
    defer visited.deinit();

    if (obstacle.x == start.pos.x and obstacle.y == start.pos.y) return false;

    var _map: Map = map;
    _map.additional_obstacle = obstacle;

    try visited.put(start, {});

    var guard = start;
    while (guard.step(_map)) |new_guard| {
        defer guard = new_guard;

        if (visited.contains(new_guard)) {
            return true;
        }

        try visited.put(new_guard, {});
    }

    return false;
}

const LoopCheckCx = struct {
    map: Map,
    start: Guard,
    obstacle: Vec2,
    loops: *std.atomic.Value(usize),

    pub fn run(self: LoopCheckCx) void {
        const loop = checkForLoop(self.map, self.start, self.obstacle) catch |e|
            std.debug.panic("checkForLoops returned {!}", .{e});

        if (loop) {
            _ = self.loops.fetchAdd(1, .acq_rel);
        }
    }
};

pub fn main() !void {
    const input = try utils.readInput();
    const map, const guard = try Map.parse(input);

    var loops = std.atomic.Value(usize).init(0);

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = utils.alloc });
    defer pool.deinit();

    var wg = std.Thread.WaitGroup{};
    wg.reset();

    var y: i32 = 0;
    while (y < map.height) : (y += 1) {
        var x: i32 = 0;
        while (x < map.width) : (x += 1) {
            const cx = LoopCheckCx{
                .map = map,
                .start = guard,
                .obstacle = vec2(x, y),
                .loops = &loops,
            };

            pool.spawnWg(&wg, LoopCheckCx.run, .{cx});
        }
    }

    pool.waitAndWork(&wg);

    try std.io.getStdOut().writer().print("{d}\n", .{loops.load(.acquire)});
}
