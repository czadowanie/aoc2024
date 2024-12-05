const std = @import("std");
const utils = @import("utils.zig");

const DependencyIter = struct {
    lines: std.mem.SplitIterator(u8, .scalar),

    pub const Dep = struct {
        page: u8,
        depends_on: u8,
    };

    pub fn init(input: []const u8) DependencyIter {
        const lines = std.mem.splitScalar(u8, input, '\n');

        return DependencyIter{
            .lines = lines,
        };
    }

    pub fn next(self: *DependencyIter) ?Dep {
        const line = self.lines.next() orelse return null;
        if (line.len == 0) {
            return null;
        }

        var parts = std.mem.splitScalar(u8, line, '|');

        const depends_on = std.fmt.parseInt(
            u8,
            parts.next() orelse return null,
            10,
        ) catch return null;
        const page = std.fmt.parseInt(
            u8,
            parts.next() orelse return null,
            10,
        ) catch return null;

        return Dep{
            .page = page,
            .depends_on = depends_on,
        };
    }

    pub fn rest(self: DependencyIter) []const u8 {
        const start = self.lines.index orelse return "";
        return self.lines.buffer[start..];
    }
};

pub fn isCorrect(appeared: *std.AutoArrayHashMap(u8, u8), dep_map: std.AutoArrayHashMap(
    u8,
    std.ArrayList(u8),
), update: []const u8) !bool {
    return order: for (update) |page| {
        try appeared.put(page, undefined);

        if (dep_map.get(page)) |dependants| {
            for (dependants.items) |dependant| {
                if (appeared.contains(dependant)) {
                    std.log.debug("rule {d}|{d} broken", .{ page, dependant });
                    break :order false;
                }
            }
        }
    } else true;
}

pub fn fixup(
    appeared: *std.AutoArrayHashMap(u8, u8),
    dep_map: std.AutoArrayHashMap(u8, std.ArrayList(u8)),
    update: []u8,
) !bool {
    return order: for (0..update.len) |i| {
        const page = update[i];

        try appeared.put(page, @intCast(i));

        if (dep_map.get(page)) |dependants| {
            for (dependants.items) |dependant| {
                if (appeared.contains(dependant)) {
                    std.log.debug("rule {d}|{d} broken", .{ page, dependant });

                    const dependant_index = appeared.get(dependant).?;
                    std.mem.swap(u8, &update[i], &update[dependant_index]);

                    break :order false;
                }
            }
        }
    } else true;
}

pub fn main() !void {
    const input = try utils.readInput();

    var dep_map = std.AutoArrayHashMap(u8, std.ArrayList(u8)).init(utils.alloc);
    var deps_iter = DependencyIter.init(input);
    while (deps_iter.next()) |dep| {
        std.log.debug("{any}", .{dep});
        const res = try dep_map.getOrPut(dep.depends_on);
        if (res.found_existing) {
            try res.value_ptr.append(dep.page);
        } else {
            res.value_ptr.* = std.ArrayList(u8).init(utils.alloc);
            try res.value_ptr.append(dep.page);
        }
    }

    const rest = deps_iter.rest();
    var updates = std.mem.splitScalar(u8, rest, '\n');
    var mid_page_sum: u64 = 0;

    var appeared = std.AutoArrayHashMap(u8, u8).init(utils.alloc);
    while (updates.next()) |update| {
        defer appeared.clearRetainingCapacity();

        std.log.debug("-- UPDATE --", .{});

        if (update.len == 0) {
            break;
        }

        var pages_txt = std.mem.splitScalar(u8, update, ',');
        var pages = std.ArrayList(u8).init(utils.alloc);
        defer pages.deinit();
        while (pages_txt.next()) |txt| {
            try pages.append(try std.fmt.parseInt(u8, txt, 10));
        }

        std.log.debug("update = {d}", .{pages.items});

        const correct = try isCorrect(&appeared, dep_map, pages.items);
        appeared.clearRetainingCapacity();

        std.log.debug("right_order = {}", .{correct});

        if (correct) continue;

        var i: usize = 0;
        while (try fixup(&appeared, dep_map, pages.items) == false) : (i += 1) {
            std.log.debug("fixup {d} = {d}", .{ i, pages.items });
            appeared.clearRetainingCapacity();
        }

        const midpoint = (pages.items.len - 1) / 2;
        mid_page_sum += pages.items[midpoint];
    }

    try std.io.getStdOut().writer().print("{d}\n", .{mid_page_sum});
}
