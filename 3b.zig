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

const OpTy = enum {
    mul,
    do,
    dont,
};

const Op = union(OpTy) {
    mul: Mul,
    do,
    dont,
};

const OpPos = struct {
    ty: OpTy,
    pos: ?usize,
};

const OpIter = struct {
    input: []const u8,
    pos: usize = 0,

    fn tryNextMul(self: OpIter, from: *usize) ?usize {
        const start = std.mem.indexOfPos(
            u8,
            self.input,
            from.*,
            "mul(",
        ) orelse return null;
        from.* = start + 4;

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
            from.* = start + 4;
            return null;
        }

        _ = std.fmt.parseInt(
            u32,
            self.input[start + 4 .. comma],
            10,
        ) catch return null;

        _ = std.fmt.parseInt(
            u32,
            self.input[comma + 1 .. end],
            10,
        ) catch return null;

        from.* = end + 1;

        return start;
    }

    pub fn nextMul(self: *OpIter) ?usize {
        var prev_pos: usize = std.math.maxInt(usize);
        var in_row: u32 = 0;

        var from = self.pos;

        while (in_row < 2) {
            if (from == prev_pos) {
                in_row += 1;
            } else {
                in_row = 0;
            }

            if (self.tryNextMul(&from)) |pos| {
                return pos;
            }

            prev_pos = from;
        }

        return null;
    }

    fn next(self: *OpIter) ?Op {
        var choices = [3]OpPos{
            OpPos{
                .ty = .do,
                .pos = std.mem.indexOfPos(
                    u8,
                    self.input,
                    self.pos,
                    "do()",
                ),
            },
            OpPos{
                .ty = .dont,
                .pos = std.mem.indexOfPos(
                    u8,
                    self.input,
                    self.pos,
                    "don't()",
                ),
            },
            OpPos{
                .ty = .mul,
                .pos = self.nextMul(),
            },
        };

        std.mem.sort(OpPos, &choices, {}, (struct {
            pub fn isLessThan(_: void, a: OpPos, b: OpPos) bool {
                if (a.pos) |apos| {
                    if (b.pos) |bpos| {
                        return apos < bpos;
                    } else return true;
                } else return false;
            }
        }).isLessThan);

        const best = choices[0];

        if (best.pos) |start| {
            switch (best.ty) {
                OpTy.do => {
                    self.pos = start + 3;
                    return Op.do;
                },
                OpTy.dont => {
                    self.pos = start + 6;
                    return Op.dont;
                },
                OpTy.mul => {
                    const comma = std.mem.indexOfPos(u8, self.input, start, ",").?;
                    const end = std.mem.indexOfPos(u8, self.input, start, ")").?;

                    self.pos = end;

                    return Op{
                        .mul = Mul{
                            .a = std.fmt.parseInt(
                                u32,
                                self.input[start + 4 .. comma],
                                10,
                            ) catch unreachable,
                            .b = std.fmt.parseInt(
                                u32,
                                self.input[comma + 1 .. end],
                                10,
                            ) catch unreachable,
                        },
                    };
                },
            }
        } else return null;
    }
};

pub fn main() !void {
    const input = try utils.readInput();
    var iter = OpIter{ .input = input };

    var out: u64 = 0;
    var do: bool = true;
    while (iter.next()) |op| {
        switch (op) {
            .mul => |mul| {
                if (do) {
                    out += mul.exec(u64);
                }
            },
            .do => {
                do = true;
            },
            .dont => {
                do = false;
            },
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{out});
}
