const std = @import("std");
const utils = @import("utils.zig");

const Equation = struct {
    result: u64,
    terms: []const u32,
};

const EquationIter = struct {
    lines: std.mem.SplitIterator(u8, .scalar),
    terms: std.ArrayList(u32),

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !EquationIter {
        return EquationIter{
            .lines = std.mem.splitScalar(u8, input, '\n'),
            .terms = try std.ArrayList(u32).initCapacity(allocator, 64),
        };
    }

    pub fn next(self: *EquationIter) ?Equation {
        const line = self.lines.next() orelse return null;
        if (line.len == 0) return null;

        self.terms.clearRetainingCapacity();

        var parts = std.mem.splitScalar(u8, line, ':');
        const result_text = parts.next() orelse return null;
        const result = std.fmt.parseInt(
            u64,
            result_text,
            10,
        ) catch std.debug.panic("invalid result '{s}'", .{result_text});

        const terms_sequenece = parts.next() orelse return null;
        var terms = std.mem.splitScalar(u8, terms_sequenece[1..], ' ');

        while (terms.next()) |term| {
            self.terms.appendAssumeCapacity(std.fmt.parseInt(u32, term, 10) catch std.debug.panic(
                "invalid term '{s}'",
                .{term},
            ));
        }

        return Equation{
            .result = result,
            .terms = self.terms.items,
        };
    }
};

const Op = enum(u1) {
    add,
    mul,
};
const n_ops = 2;

fn genOpTreeImpl(history: *std.ArrayList(Op), ops: *std.ArrayList(Op), depth: usize, max_depth: usize) !void {
    if (depth == max_depth) {
        try ops.appendSlice(history.items);
    } else {
        try history.append(Op.add);
        try genOpTreeImpl(history, ops, depth + 1, max_depth);

        try history.append(Op.mul);
        try genOpTreeImpl(history, ops, depth + 1, max_depth);
    }

    _ = history.popOrNull();
}

fn genOpTree(max_depth: usize) ![]const Op {
    var history = std.ArrayList(Op).init(utils.alloc);
    var ops = try std.ArrayList(Op).initCapacity(utils.alloc, std.math.pow(u64, n_ops, max_depth) * max_depth);

    try genOpTreeImpl(&history, &ops, 0, max_depth);

    return ops.items;
}

const OpTreeIter = struct {
    ops: []const Op,
    pos: usize = 0,
    depth: usize,
    stride: usize,

    pub fn init(ops: []const Op, depth: usize, max_depth: usize) !OpTreeIter {
        if (depth > max_depth)
            return error.TreeTooShallow;

        return OpTreeIter{
            .ops = ops,
            .depth = depth,
            .stride = (std.math.pow(u64, n_ops, max_depth) * max_depth) / std.math.pow(u64, n_ops, depth),
        };
    }

    pub fn next(self: *OpTreeIter) ?[]const Op {
        if (self.pos == self.ops.len) return null;

        const chunk = self.ops[self.pos .. self.pos + self.depth];

        self.pos += self.stride;

        return chunk;
    }
};

fn eval(terms: []const u32, ops: []const Op) u64 {
    var result = @as(u64, terms[0]);

    for (terms[1..], ops) |term, op| {
        switch (op) {
            .add => result += @as(u64, term),
            .mul => result *= @as(u64, term),
        }
    }

    return result;
}

pub fn main() !void {
    const input = try utils.readInput();
    var eq_iter = try EquationIter.init(utils.alloc, input);

    const max_depth = 11;

    var sum: u64 = 0;
    const tree = try genOpTree(max_depth);
    outer: while (eq_iter.next()) |eq| {
        std.log.debug("{any}", .{eq});

        var ops_iter = try OpTreeIter.init(tree, eq.terms.len - 1, max_depth);
        while (ops_iter.next()) |ops| {
            const res = eval(eq.terms, ops);
            if (res == eq.result) {
                sum += res;
                continue :outer;
            }
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
