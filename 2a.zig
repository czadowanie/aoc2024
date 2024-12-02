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
        std.log.debug("safe = {any}", .{report.isSafe()});
        if (report.isSafe()) {
            safe += 1;
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{safe});
}
