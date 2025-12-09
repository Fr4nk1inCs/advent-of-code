const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var count: u64 = 0;
    const first_line = (try segments.next()).?;
    const stream = try allocator.alloc(bool, first_line.len);
    defer allocator.free(stream);

    for (first_line, stream) |char, *is_beam| {
        is_beam.* = char == 'S';
    }

    while (try segments.next()) |line| {
        for (0..line.len, line, stream) |i, char, *is_beam| {
            const split = char == '^';
            if (!is_beam.*) continue;
            if (split) {
                count += 1;
                is_beam.* = false;
                stream[i - 1] = true;
                stream[i + 1] = true;
            }
        }
    }
    return count;
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    const first_line = (try segments.next()).?;
    const timelines = try allocator.alloc(u64, first_line.len);
    defer allocator.free(timelines);

    for (first_line, timelines) |char, *timeline| {
        timeline.* = switch (char) {
            'S' => 1,
            else => 0,
        };
    }

    while (try segments.next()) |line| {
        for (0..line.len, line, timelines) |i, char, *timeline| {
            const split = char == '^';
            if (timeline.* == 0) continue;
            if (split) {
                timelines[i - 1] += timeline.*;
                timelines[i + 1] += timeline.*;
                timeline.* = 0;
            }
        }
    }
    var count: u64 = 0;
    for (timelines) |timeline| {
        count += timeline;
    }
    return count;
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
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(21, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(40, result);
    }
}
