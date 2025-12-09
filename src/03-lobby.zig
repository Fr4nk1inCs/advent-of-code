const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var sum: u64 = 0;
    while (try segments.next()) |segment| {
        var voltages = try allocator.alloc(u8, segment.len);
        defer allocator.free(voltages);

        var prefix_max = try allocator.alloc(u8, segment.len);
        defer allocator.free(prefix_max);

        var suffix_max = try allocator.alloc(u8, segment.len);
        defer allocator.free(suffix_max);

        var max_so_far: u8 = 0;

        for (0..segment.len) |i| {
            voltages[i] = segment[i] - '0';
            max_so_far = @max(max_so_far, voltages[i]);
            prefix_max[i] = max_so_far;
        }
        max_so_far = 0;

        var _i: usize = segment.len;
        while (_i > 0) : (_i -= 1) {
            max_so_far = @max(max_so_far, voltages[_i - 1]);
            suffix_max[_i - 1] = max_so_far;
        }

        var largest_joltage: u8 = 0;
        for (1..segment.len) |i| {
            const left_max = prefix_max[i - 1];
            const right_max = suffix_max[i];
            const candidate = left_max * 10 + right_max;
            largest_joltage = @max(largest_joltage, candidate);
        }
        sum += largest_joltage;
    }
    return sum;
}

const NUM_BATTERIES_PART2 = 12;
const Entry = struct {
    value: u8,
    index: usize,
};

// We want the smallest value at the front of the window to be popped first
fn compareEntry(context: void, a: Entry, b: Entry) std.math.Order {
    _ = context;
    if (a.value < b.value) return .lt;
    if (a.value > b.value) return .gt;
    return std.math.order(a.index, b.index);
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var sum: u64 = 0;

    while (try segments.next()) |segment| {
        var voltages = try allocator.alloc(u8, segment.len);
        defer allocator.free(voltages);

        for (0..segment.len) |i| {
            voltages[i] = segment[i] - '0';
        }

        var produced: u64 = 0;
        var start: usize = 0;
        for (0..NUM_BATTERIES_PART2) |i| {
            var max = voltages[start];
            start += 1;
            const end = segment.len - NUM_BATTERIES_PART2 + i + 1;
            for (start..end) |j| {
                if (voltages[j] > max) {
                    max = voltages[j];
                    start = j + 1;
                }
            }
            produced = produced * 10 + max;
        }
        sum += produced;
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
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator, allocator);
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "aoc-test" {
    const testcase =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(357, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(3121910778619, result);
    }
}
