const std = @import("std");

const utils = @import("utils.zig");
const get_input_file = utils.get_input_file;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

const Op = enum {
    Add,
    Multiply,
};

fn parse_number_line(line: []const u8, allocator: std.mem.Allocator) !std.ArrayList(u64) {
    var parts = std.mem.tokenizeScalar(u8, line, ' ');

    var numbers = try std.ArrayList(u64).initCapacity(allocator, 16);

    while (parts.next()) |part| {
        const num = try std.fmt.parseInt(u64, part, 10);
        try numbers.append(allocator, num);
    }

    return numbers;
}

fn parse_op_line(line: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Op) {
    var parts = std.mem.tokenizeScalar(u8, line, ' ');

    var ops = try std.ArrayList(Op).initCapacity(allocator, 16);

    while (parts.next()) |part| {
        const op = switch (part[0]) {
            '+' => Op.Add,
            '*' => Op.Multiply,
            else => unreachable,
        };
        try ops.append(allocator, op);
    }

    return ops;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var lines: std.ArrayList(std.ArrayList(u64)) = try std.ArrayList(std.ArrayList(u64)).initCapacity(allocator, 4);
    defer {
        for (lines.items) |*line| {
            line.deinit(allocator);
        }
        lines.deinit(allocator);
    }

    var ops: std.ArrayList(Op) = undefined;
    while (try segments.next()) |line| {
        if (try segments.eos()) {
            ops = try parse_op_line(line, allocator);
        } else {
            try lines.append(allocator, try parse_number_line(line, allocator));
        }
    }
    defer {
        ops.deinit(allocator);
    }

    var result: u64 = 0;
    const n = ops.items.len;
    for (0..n) |i| {
        const op = ops.items[i];

        var entry: u64 = switch (op) {
            .Add => 0,
            .Multiply => 1,
        };
        for (lines.items) |line| {
            switch (op) {
                .Add => entry += line.items[i],
                .Multiply => entry *= line.items[i],
            }
        }

        result += entry;
    }
    return result;
}

const Lines = struct {
    inner: std.ArrayList([]u8),

    pub fn init(allocator: std.mem.Allocator) !Lines {
        return Lines{
            .inner = try std.ArrayList([]u8).initCapacity(allocator, 4),
        };
    }

    pub fn deinit(self: *Lines, allocator: std.mem.Allocator) void {
        for (self.inner.items) |line| {
            allocator.free(line);
        }
        self.inner.deinit(allocator);
    }

    pub fn append(self: *Lines, line: []u8, allocator: std.mem.Allocator) !void {
        const line_copy = try allocator.alloc(u8, line.len);
        @memcpy(line_copy, line);
        try self.inner.append(allocator, line_copy);
    }

    pub fn from_segments(segments: *SegmentIterator, allocator: std.mem.Allocator) !Lines {
        var lines = try Lines.init(allocator);

        while (try segments.next()) |line| {
            try lines.append(line, allocator);
        }

        return lines;
    }
};

const Problem = struct {
    values: []u64,
    op: Op,

    pub fn init(values: []u64, op: Op) Problem {
        return Problem{
            .values = values,
            .op = op,
        };
    }

    pub fn execute(self: *Problem) !u64 {
        var result: u64 = switch (self.op) {
            .Add => 0,
            .Multiply => 1,
        };
        for (self.values) |value| {
            switch (self.op) {
                .Add => result += value,
                .Multiply => result *= value,
            }
        }
        return result;
    }

    pub fn deinit(self: *Problem, allocator: std.mem.Allocator) !void {
        allocator.free(self.values);
    }
};

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var lines = try Lines.from_segments(segments, allocator);
    defer lines.deinit(allocator);

    const n = lines.inner.items.len;
    const m = lines.inner.items[0].len;

    // Parse blocks into problems
    var start: usize = 0;
    var problems: std.ArrayList(Problem) = try std.ArrayList(Problem).initCapacity(allocator, 16);
    defer {
        for (problems.items) |*problem| {
            problem.deinit(allocator) catch {};
        }
        problems.deinit(allocator);
    }

    var num_buf = try allocator.alloc(u8, n - 1);
    defer allocator.free(num_buf);

    while (start < m) {
        const op_char = lines.inner.items[n - 1][start];
        const op = switch (op_char) {
            '+' => Op.Add,
            '*' => Op.Multiply,
            else => unreachable,
        };
        var next = start + 1;
        while (next < m and lines.inner.items[n - 1][next] == ' ') : (next += 1) {}
        const end = if (next == m) m else next - 1;

        const len = end - start;
        const values = try allocator.alloc(u64, len);
        var i: usize = end;
        while (i > start) : (i -= 1) {
            for (0..n - 1) |line_idx| {
                num_buf[line_idx] = lines.inner.items[line_idx][i - 1];
            }
            const num = try std.fmt.parseInt(u64, std.mem.trim(u8, num_buf, " "), 10);
            values[i - start - 1] = num;
        }
        try problems.append(allocator, Problem.init(values, op));
        start = next;
    }

    var result: u64 = 0;
    for (problems.items) |*problem| {
        const value = try problem.execute();
        result += value;
    }
    return result;
}

pub fn main() !void {
    var input_file = try get_input_file();
    defer input_file.close();

    var read_buf: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.err("Memory Leak!", .{});
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        std.debug.print("Part 1: {}\n", .{result});
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        std.debug.print("Part 2: {}\n", .{result});
    }
}

test "aoc-test" {
    const testcase =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(4277556, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(3263827, result);
    }
}
