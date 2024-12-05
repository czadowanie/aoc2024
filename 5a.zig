const std = @import("std");
const utils = @import("utils.zig");

const DependencyIter = struct {
    lines: std.mem.SplitIterator(u8, .scalar),

    pub const Dep = struct {
        page: u32,
        depends_on: u32,
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
            u32,
            parts.next() orelse return null,
            10,
        ) catch return null;
        const page = std.fmt.parseInt(
            u32,
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

pub fn main() !void {
    const input = try utils.readInput();

    var dep_map = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(utils.alloc);
    var deps_iter = DependencyIter.init(input);
    while (deps_iter.next()) |dep| {
        std.log.debug("{any}", .{dep});
        const res = try dep_map.getOrPut(dep.depends_on);
        if (res.found_existing) {
            try res.value_ptr.append(dep.page);
        } else {
            res.value_ptr.* = std.ArrayList(u32).init(utils.alloc);
            try res.value_ptr.append(dep.page);
        }
    }

    const rest = deps_iter.rest();
    var updates = std.mem.splitScalar(u8, rest, '\n');

    var appeared = std.AutoArrayHashMap(u32, void).init(utils.alloc);
    var mid_page_sum: u64 = 0;
    while (updates.next()) |update| {
        defer appeared.clearRetainingCapacity();
        std.log.debug("-- UPDATE --", .{});

        if (update.len == 0) {
            break;
        }

        var pages = std.mem.splitScalar(u8, update, ',');
        var n_pages: usize = 0;
        const right_order: bool = order: while (pages.next()) |page_txt| {
            n_pages += 1;

            const page = try std.fmt.parseInt(u32, page_txt, 10);
            try appeared.put(page, {});

            if (dep_map.get(page)) |dependants| {
                for (dependants.items) |dependant| {
                    if (appeared.contains(dependant)) {
                        std.log.debug("rule {d}|{d} broken", .{ page, dependant });
                        break :order false;
                    }
                }
            }
        } else true;

        std.log.debug("update = {s}", .{update});
        std.log.debug("right_order = {}", .{right_order});

        if (!right_order) continue;

        const midpoint = (n_pages - 1) / 2;
        pages = std.mem.splitScalar(u8, update, ',');

        var i: usize = 0;
        const mid_page_number = while (pages.next()) |page| : (i += 1) {
            if (i == midpoint)
                break try std.fmt.parseInt(u32, page, 10);
        } else unreachable;

        std.log.debug("mid page number = {d}", .{mid_page_number});

        mid_page_sum += mid_page_number;
    }

    try std.io.getStdOut().writer().print("{d}\n", .{mid_page_sum});
}
