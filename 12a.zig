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
        ];
    }

    pub fn neighbors(self: *const Map, at: Vec2) Neighbors {
        return Neighbors{
            .map = self,
            .pos = at,
            .tried = 0,
        };
    }

    pub const Neighbors = struct {
        map: *const Map,
        pos: Vec2,
        tried: usize,

        pub fn next(self: *Neighbors) ?Vec2 {
            const dirs = [4]Vec2{
                Vec2{ 0, -1 },
                Vec2{ 1, 0 },
                Vec2{ 0, 1 },
                Vec2{ -1, 0 },
            };

            while (self.tried < dirs.len) {
                defer self.tried += 1;

                const new_pos = self.pos + dirs[self.tried];

                if (self.map.get(new_pos[0], new_pos[1]) == null) continue;

                return new_pos;
            }

            return null;
        }
    };
};

const print = std.debug.print;

const RegionMap = std.AutoHashMap(Vec2, *Region);

fn findRegions(map: Map) ![]const Region {
    var region_map = RegionMap.init(utils.alloc);

    var regions = std.ArrayList(*Region).init(utils.alloc);
    for (0..map.height) |y| {
        for (0..map.width) |x| {
            const ty = map.get(x, y) orelse unreachable;
            const pos = Vec2{ @intCast(x), @intCast(y) };

            print("{?c}", .{ty});

            var neigbors = map.neighbors(pos);
            while (neigbors.next()) |neigh| {
                const neigh_region = region_map.get(neigh) orelse continue;
                if (neigh_region.ty != ty) continue;

                try neigh_region.plots.put(pos, {});

                try region_map.put(pos, neigh_region);
            }

            if (region_map.get(pos) == null) {
                const region = try utils.alloc.create(Region);
                region.* = .{
                    .ty = ty,
                    .plots = std.AutoArrayHashMap(Vec2, void).init(utils.alloc),
                };

                try region.plots.put(pos, {});
                try region_map.put(pos, region);

                try regions.append(region);
            }
        }
        print("\n", .{});
    }

    for (regions.items) |a| {
        for (regions.items) |b| {
            if (!areConnected(a, b)) continue;

            try a.merge(b);
            try b.merge(a);
        }
    }

    var deduped = std.ArrayList(Region).init(utils.alloc);

    outer: for (regions.items) |a| {
        for (deduped.items) |b| {
            if (areConnected(a, &b)) continue :outer;
        }

        try deduped.append(a.*);
    }

    return deduped.items;
}

pub fn areConnected(a: *const Region, b: *const Region) bool {
    if (a.ty != b.ty) return false;

    for (b.plots.keys()) |item| {
        if (a.plots.contains(item)) return true;
    }

    return false;
}

pub const Region = struct {
    ty: u8,
    plots: std.AutoArrayHashMap(Vec2, void),

    pub fn calcPerim(self: Region, map: Map) usize {
        var perim: usize = 0;

        for (self.plots.keys()) |plot| {
            var neighs = map.neighbors(plot);

            var contacts: usize = 0;
            while (neighs.next()) |neigh| {
                if (map.get(neigh[0], neigh[1]) == self.ty) {
                    contacts += 1;
                }
            }

            perim += 4 - contacts;
        }

        return perim;
    }

    pub fn merge(lhs: *Region, rhs: *const Region) !void {
        if (lhs == rhs) return;

        for (rhs.plots.keys()) |pos| {
            try lhs.plots.put(pos, {});
        }
    }
};

pub fn main() !void {
    const input = try utils.readInput();
    const map = Map.parse(input);
    const regions = try findRegions(map);

    var sum: usize = 0;
    for (regions) |region| {
        std.log.debug("{c} -> {d}", .{ region.ty, region.plots.keys() });
        std.log.debug("area = {d}", .{region.plots.keys().len});
        std.log.debug("perim = {d}", .{region.calcPerim(map)});

        sum += region.plots.keys().len * region.calcPerim(map);
    }

    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
