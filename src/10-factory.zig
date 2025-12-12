const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

const MAX_NUM_LIGHTS = 10;
const Switches = std.bit_set.IntegerBitSet(MAX_NUM_LIGHTS);

const Machine = struct {
    size: usize,
    target: Switches,
    buttons: std.ArrayList(Switches),
    joltages: []const u32,

    pub fn parse(
        allocator: std.mem.Allocator,
        line: []const u8,
    ) !Machine {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const target_size = try Machine.parseTarget(tokens.next().?);
        const target = target_size.@"0";
        const size = target_size.@"1";

        var buttons = try std.ArrayList(Switches).initCapacity(allocator, 8);
        while (tokens.next()) |token| {
            switch (token[0]) {
                '(' => {
                    try buttons.append(allocator, try Machine.parseButton(token));
                },
                '{' => {
                    const joltages = try Machine.parseJoltage(token, size, allocator);
                    return Machine{
                        .size = size,
                        .target = target,
                        .buttons = buttons,
                        .joltages = joltages,
                    };
                },
                else => unreachable,
            }
        }
        unreachable;
    }

    fn parseTarget(token: []const u8) !struct { Switches, usize } {
        const size = token.len - 2; // remove [ and ]
        var result = Switches.initEmpty();
        for (0..size, token[1..(size + 1)]) |i, c| {
            if (c == '#') {
                result.set(i);
            }
        }
        return .{ result, size };
    }

    fn parseButton(token: []const u8) !Switches {
        var result = Switches.initEmpty();
        var tokens = std.mem.tokenizeScalar(u8, token[1..(token.len - 1)], ',');
        while (tokens.next()) |repr| {
            const index = try std.fmt.parseInt(usize, repr, 10);
            result.set(index);
        }
        return result;
    }

    fn parseJoltage(token: []const u8, size: usize, allocator: std.mem.Allocator) ![]u32 {
        var result = try allocator.alloc(u32, size);
        var tokens = std.mem.tokenizeScalar(u8, token[1..(token.len - 1)], ',');
        var i: usize = 0;
        while (tokens.next()) |repr| {
            result[i] = try std.fmt.parseInt(u32, repr, 10);
            i += 1;
        }
        return result;
    }

    pub fn deinit(self: *Machine, allocator: std.mem.Allocator) void {
        self.buttons.deinit(allocator);
        allocator.free(self.joltages);
    }
};

fn solve1(target: Switches, buttons: []const Switches) ?u32 {
    if (buttons.len == 0) {
        if (target.mask == 0) {
            return 0;
        } else {
            return null;
        }
    }

    var result: ?u32 = null;
    const button = buttons[0];

    // without toggle
    if (solve1(target, buttons[1..])) |res| {
        result = res;
    }

    // with toggle
    const new_target = target.xorWith(button);
    if (solve1(new_target, buttons[1..])) |res| {
        const candidate = res + 1;
        if (result == null or candidate < result.?) {
            result = candidate;
        }
    }
    return result;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u32 {
    var sum: u32 = 0;
    while (try segments.next()) |segment| {
        var machine = try Machine.parse(allocator, segment);
        defer machine.deinit(allocator);

        sum += solve1(machine.target, machine.buttons.items).?;
    }
    return sum;
}

pub fn Matrix(comptime T: type) type {
    return struct {
        rows: usize,
        cols: usize,
        data: []T,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Self {
            const data = try allocator.alloc(T, rows * cols);
            return Self{
                .rows = rows,
                .cols = cols,
                .data = data,
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.data);
        }

        pub inline fn get(self: *const Self, row: usize, col: usize) T {
            return self.data[row * self.cols + col];
        }

        pub inline fn set(self: *Self, row: usize, col: usize, value: T) void {
            self.data[row * self.cols + col] = value;
        }

        inline fn ptr(self: *Self, row: usize, col: usize) *T {
            return &self.data[row * self.cols + col];
        }

        fn swapRow(self: *Self, row1: usize, row2: usize) void {
            for (0..self.cols) |col| {
                std.mem.swap(T, self.ptr(row1, col), self.ptr(row2, col));
            }
        }

        fn swapCol(self: *Self, col1: usize, col2: usize) void {
            for (0..self.rows) |row| {
                std.mem.swap(T, self.ptr(row, col1), self.ptr(row, col2));
            }
        }
    };
}

fn GuassianElimination(comptime T: type) type {
    return struct {
        rank: usize,

        _matrix: *Matrix(T),
        _y: []T,

        const Self = @This();

        pub fn forward(allocator: std.mem.Allocator, matrix: *Matrix(T), y: []T) !Self {
            const max_rank = @min(matrix.rows, matrix.cols);

            var rank: usize = 0;
            var pivot_cols = try allocator.alloc(usize, max_rank);
            defer allocator.free(pivot_cols);

            var pivot_row: usize = 0;
            var pivot_col: usize = 0;
            var prev_pivot: T = 1;

            while (pivot_row < matrix.rows and pivot_col < matrix.cols) {
                var target_row: ?usize = null;
                for (pivot_row..matrix.rows) |r| {
                    if (matrix.get(r, pivot_col) != 0) {
                        target_row = r;
                        break;
                    }
                }

                if (target_row == null) {
                    pivot_col += 1;
                    continue;
                }

                if (target_row.? != pivot_row) {
                    matrix.swapRow(pivot_row, target_row.?);
                    std.mem.swap(T, &y[pivot_row], &y[target_row.?]);
                }

                pivot_cols[rank] = pivot_col;
                rank += 1;

                const pivot_val = matrix.get(pivot_row, pivot_col);
                for (pivot_row + 1..matrix.rows) |i| {
                    const factor = matrix.get(i, pivot_col);
                    for (pivot_col..matrix.cols) |j| {
                        const val = matrix.get(i, j) * pivot_val - matrix.get(pivot_row, j) * factor;
                        matrix.set(i, j, @divExact(val, prev_pivot));
                    }
                    const y_val = y[i] * pivot_val - y[pivot_row] * factor;
                    y[i] = @divExact(y_val, prev_pivot);
                }

                pivot_row += 1;
                pivot_col += 1;
                prev_pivot = pivot_val;
            }

            // Swap columns to make pivot columns diagonal
            for (0..rank) |i| {
                if (i != pivot_cols[i]) {
                    matrix.swapCol(i, pivot_cols[i]);
                }
            }

            return Self{
                .rank = rank,

                ._matrix = matrix,
                ._y = y,
            };
        }

        pub fn isConsistent(self: *const Self) bool {
            for (self.rank..self._y.len) |i| {
                if (self._y[i] != 0) {
                    return false;
                }
            }
            return true;
        }

        pub fn backSubstitute(self: *const Self, variables: []T) !?T {
            const n = self._matrix.cols;

            for (0..self.rank) |i_rev| {
                const i = self.rank - 1 - i_rev;
                var sum: T = 0;
                for (i + 1..n) |j| {
                    sum += self._matrix.get(i, j) * variables[j];
                }
                const val = self._y[i] - sum;
                const pivot = self._matrix.get(i, i);
                if (@rem(val, pivot) != 0) {
                    return null;
                }
                const sol = @divExact(val, pivot);
                if (sol < 0) {
                    return null;
                }

                variables[i] = @divExact(val, pivot);
            }

            var sum: T = 0;
            for (0..self.rank) |i| {
                sum += variables[i];
            }
            return sum;
        }
    };
}

// Returns a transposed representation of the buttons
fn buttonsToMatrix(comptime T: type, allocator: std.mem.Allocator, buttons: []Switches, num_lights: usize) !Matrix(i32) {
    const rows = num_lights;
    const cols = buttons.len;
    var matrix = try Matrix(T).init(allocator, rows, cols);
    for (0..cols) |col| {
        const button = buttons[col];
        for (0..rows) |row| {
            matrix.set(row, col, @intFromBool(button.isSet(row)));
        }
    }
    return matrix;
}

fn filterAllZero(comptime T: type, allocator: std.mem.Allocator, matrix: *Matrix(T), rank: usize) !Matrix(T) {
    const rows = rank;
    const cols = matrix.cols;
    var col_idxs = try allocator.alloc(usize, cols);
    defer allocator.free(col_idxs);

    for (0..rank) |i| {
        col_idxs[i] = i;
    }

    var count: usize = rank;
    for (rank..cols) |col| {
        var all_zero = true;
        for (0..rows) |row| {
            if (matrix.get(row, col) != 0) {
                all_zero = false;
                break;
            }
        }
        if (!all_zero) {
            col_idxs[count] = col;
            count += 1;
        }
    }

    var result = try Matrix(T).init(allocator, rows, count);
    for (0..rows) |row| {
        for (0..count) |i| {
            result.set(row, i, matrix.get(row, col_idxs[i]));
        }
    }
    return result;
}

fn searchFreeVars(
    comptime T: type,
    ge: *const GuassianElimination(T),
    idx: usize,
    variables: []T,
    curr_cost: T,
    min_cost: *T,
    bound: T,
) !void {
    if (idx == variables.len) {
        if (try ge.backSubstitute(variables)) |sum| {
            min_cost.* = @min(min_cost.*, sum + curr_cost);
        }

        return;
    }

    const limit: T = @min(bound, min_cost.* - curr_cost);
    for (0..@as(usize, @intCast(limit))) |uv| {
        const iv = @as(T, @intCast(uv));
        variables[idx] = iv;
        if (iv + curr_cost >= min_cost.*) {
            break;
        }
        try searchFreeVars(T, ge, idx + 1, variables, curr_cost + iv, min_cost, bound);
    }
}

fn bruteForce(
    comptime T: type,
    allocator: std.mem.Allocator,
    ge: *const GuassianElimination(T),
    bound: T,
) !T {
    const n = ge._matrix.cols;
    const variables = try allocator.alloc(T, n);
    defer allocator.free(variables);

    var min_cost: T = std.math.maxInt(T);
    try searchFreeVars(T, ge, ge.rank, variables, 0, &min_cost, bound);
    return min_cost;
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !i32 {
    var sum: i32 = 0;
    while (try segments.next()) |segment| {
        var machine = try Machine.parse(allocator, segment);
        defer machine.deinit(allocator);

        var matrix = try buttonsToMatrix(i32, allocator, machine.buttons.items, machine.size);
        defer matrix.deinit(allocator);

        const y = try allocator.alloc(i32, machine.size);
        defer allocator.free(y);
        var bound: i32 = 0;
        for (y, machine.joltages) |*p, j| {
            p.* = @as(i32, @intCast(j));
            bound = @max(bound, p.*);
        }
        bound += 1;

        var ge = try GuassianElimination(i32).forward(allocator, &matrix, y);
        if (!ge.isConsistent()) {
            return error.NoSolution;
        }

        var filtered = try filterAllZero(i32, allocator, &matrix, ge.rank);
        defer filtered.deinit(allocator);

        ge = GuassianElimination(i32){
            .rank = ge.rank,
            ._matrix = &filtered,
            ._y = y[0..ge.rank],
        };

        const min_press = try bruteForce(i32, allocator, &ge, bound);
        sum += min_press;
    }
    return sum;
}

pub fn main() !void {
    var input_file = try getInputFile();
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
        var timer = try std.time.Timer.start();
        const result = try part1(&reader.iterator, allocator);
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator, allocator);
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "aoc-test" {
    const testcase =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(7, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(33, result);
    }
}
