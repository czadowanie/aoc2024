const std = @import("std");
const utils = @import("utils.zig");

const Mul = struct {
    a: u32,
    b: u32,

    pub fn exec(self: Mul, T: type) T {
        const a: T = @intCast(self.a);
        const b: T = @intCast(self.b);
        return a * b;
    }
};

const MulIter = struct {
    input: []const u8,
    pos: usize = 0,

    fn tryNext(self: *MulIter) ?Mul {
        const start = std.mem.indexOfPos(
            u8,
            self.input,
            self.pos,
            "mul(",
        ) orelse return null;
        self.pos = start + 4;

        const comma = std.mem.indexOfPos(
            u8,
            self.input,
            start,
            ",",
        ) orelse return null;

        const end = std.mem.indexOfPos(
            u8,
            self.input,
            start,
            ")",
        ) orelse return null;

        if (end < comma) {
            return null;
        }

        const a = std.fmt.parseInt(
            u32,
            self.input[start + 4 .. comma],
            10,
        ) catch return null;

        const b = std.fmt.parseInt(
            u32,
            self.input[comma + 1 .. end],
            10,
        ) catch return null;

        self.pos = end + 1;

        return Mul{
            .a = a,
            .b = b,
        };
    }

    pub fn next(self: *MulIter) ?Mul {
        var prev_pos: usize = std.math.maxInt(usize);
        var in_row: u32 = 0;

        while (in_row < 2) {
            if (self.pos == prev_pos) {
                in_row += 1;
            } else {
                in_row = 0;
            }
            if (self.tryNext()) |mul| {
                return mul;
            }

            prev_pos = self.pos;
        }

        return null;
    }
};

pub fn main() !void {
    const input = try utils.readInput();
    var iter = MulIter{ .input = input };

    var out: u64 = 0;
    while (iter.next()) |mul| {
        out += mul.exec(u64);
    }

    try std.io.getStdOut().writer().print("{d}\n", .{out});
}
