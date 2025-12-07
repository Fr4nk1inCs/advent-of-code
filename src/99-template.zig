const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn part1(segments: *SegmentIterator) !void {
    while (try segments.next()) |segment| {
        _ = segment;
    }
}

fn part2(segments: *SegmentIterator) !void {
    while (try segments.next()) |segment| {
        _ = segment;
    }
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
        const result = try part1(&reader.iterator);
        std.debug.print("Part 1: {}\n", .{result});
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator);
        std.debug.print("Part 2: {}\n", .{result});
    }
}

test "aoc-test" {
    const testcase =
        \\
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator);
        try std.testing.expectEqual({}, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator);
        try std.testing.expectEqual({}, result);
    }
}
