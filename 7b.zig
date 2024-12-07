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

const Op = enum {
    add,
    mul,
    concat,
};

// I bet you could at least replace the history part with a heap position
fn genOpTree(history: *std.ArrayList(Op), ops: *std.ArrayList(Op), depth: usize, max_depth: usize) !void {
    if (depth == max_depth) {
        try ops.appendSlice(history.items);
    } else {
        try history.append(Op.add);
        try genOpTree(history, ops, depth + 1, max_depth);

        try history.append(Op.mul);
        try genOpTree(history, ops, depth + 1, max_depth);

        try history.append(Op.concat);
        try genOpTree(history, ops, depth + 1, max_depth);
    }

    _ = history.popOrNull();
}

const OpTreeIterCache = struct {
    history: std.ArrayList(Op),
    ops: std.ArrayList(Op),

    pub fn init(allocator: std.mem.Allocator) OpTreeIterCache {
        return OpTreeIterCache{
            .history = std.ArrayList(Op).init(allocator),
            .ops = std.ArrayList(Op).init(allocator),
        };
    }
};

const OpTreeIter = struct {
    ops: []const Op,
    depth: usize,

    pub fn init(cache: *OpTreeIterCache, depth: usize) !OpTreeIter {
        cache.ops.clearRetainingCapacity();
        cache.history.clearRetainingCapacity();

        try genOpTree(&cache.history, &cache.ops, 0, depth);

        return OpTreeIter{
            .ops = cache.ops.items,
            .depth = depth,
        };
    }

    pub fn next(self: *OpTreeIter) ?[]const Op {
        if (self.ops.len == 0) return null;
        const chunk = self.ops[0..self.depth];
        self.ops = self.ops[self.depth..];
        return chunk;
    }
};

fn concat(a: u64, b: u64) u64 {
    var b_copy = b;
    var b_digits: u64 = 0;
    while (b_copy != 0) : (b_digits += 1) {
        b_copy /= 10;
    }
    return std.math.pow(u64, 10, b_digits) * a + b;
}

fn eval(terms: []const u32, ops: []const Op) u64 {
    var result = @as(u64, terms[0]);

    for (terms[1..], ops) |term, op| {
        switch (op) {
            .add => result += @as(u64, term),
            .mul => result *= @as(u64, term),
            .concat => result = concat(result, @as(u64, term)),
        }
    }

    return result;
}

pub fn main() !void {
    const input = try utils.readInput();
    var eq_iter = try EquationIter.init(utils.alloc, input);

    var sum: u64 = 0;
    var cache = OpTreeIterCache.init(utils.alloc);
    outer: while (eq_iter.next()) |eq| {
        std.log.debug("{any}", .{eq});

        var ops_iter = try OpTreeIter.init(&cache, eq.terms.len - 1);
        while (ops_iter.next()) |ops| {
            std.log.debug("{any}", .{ops});

            const res = eval(eq.terms, ops);
            std.log.debug("{d}", .{res});

            if (res == eq.result) {
                sum += res;
                continue :outer;
            }
        }
    }

    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
