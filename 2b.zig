const std = @import("std");
const utils = @import("./utils.zig");

const Report = struct {
    levels: []u8,

    pub fn parse(line: []const u8) !Report {
        var items = std.mem.split(u8, line, " ");

        var arr = try std.ArrayList(u8).initCapacity(utils.alloc, 8);
        while (items.next()) |item| {
            try arr.append(try std.fmt.parseInt(u8, item, 10));
        }

        return .{
            .levels = arr.items,
        };
    }

    pub fn slice(self: Report) []const u8 {
        return self.levels;
    }

    pub fn isSafeDamper(self: Report) !bool {
        if (self.isSafe()) {
            return true;
        }

        const perms = try self.damperPerms();
        std.log.debug("perms = {any}", .{perms});

        for (perms) |perm| {
            if (perm.isSafe()) {
                return true;
            }
        }

        return false;
    }

    pub fn damperPerms(self: Report) ![]Report {
        var out = try std.ArrayList(Report).initCapacity(utils.alloc, self.levels.len);

        for (0..self.levels.len) |without| {
            const perm = try utils.alloc.alloc(u8, self.levels.len - 1);
            std.mem.copyForwards(u8, perm[0..without], self.levels[0..without]);
            std.mem.copyForwards(
                u8,
                perm[without .. self.levels.len - 1],
                self.levels[without + 1 .. self.levels.len],
            );

            try out.append(Report{ .levels = perm });
        }

        return out.items;
    }

    pub fn isSafe(self: Report) bool {
        var prev = self.slice()[0];
        const increasing: bool = prev <= self.slice()[self.slice().len - 1];

        for (self.slice()[1..]) |el| {
            if (el >= prev) {
                if (!increasing or el - prev > 3 or el == prev) {
                    return false;
                }
            } else {
                if (increasing or prev - el > 3 or el == prev) {
                    return false;
                }
            }

            prev = el;
        }

        return true;
    }
};

fn parseReports(input: []const u8) ![]Report {
    const n = utils.countLines(input);
    var arr = try std.ArrayList(Report).initCapacity(utils.alloc, n);

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len > 0) {
            arr.appendAssumeCapacity(try Report.parse(line));
        }
    }

    return arr.items;
}

pub fn main() !void {
    const input = try utils.readInput();

    const reports = try parseReports(input);

    var safe: usize = 0;
    for (reports) |report| {
        std.log.debug("report = {any}", .{report.slice()});
        if (try report.isSafeDamper()) {
            safe += 1;
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{safe});
}
