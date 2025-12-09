const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

const Cell = enum {
    Empty,
    Paper,
    Lifted,
};

const PART1_ADJACENT_UPPER_BOUND: usize = 4;

fn parse(segments: *SegmentIterator, allocator: std.mem.Allocator) !std.ArrayList(std.ArrayList(Cell)) {
    var grid = try std.ArrayList(std.ArrayList(Cell)).initCapacity(allocator, 10);

    while (try segments.next()) |segment| {
        var row = try std.ArrayList(Cell).initCapacity(allocator, segment.len);
        for (segment) |ch| {
            switch (ch) {
                '.' => row.appendAssumeCapacity(.Empty),
                '@' => row.appendAssumeCapacity(.Paper),
                else => unreachable,
            }
        }
        try grid.append(allocator, row);
    }
    return grid;
}

fn forklift(grid: *std.ArrayList(std.ArrayList(Cell))) usize {
    const m = grid.items.len;
    const n = grid.items[0].items.len;

    var count: usize = 0;

    for (0..m) |i| {
        for (0..n) |j| {
            if (grid.items[i].items[j] != .Paper) continue;
            var paper_count_adjacent: usize = 0;
            for (@max(0, @as(isize, @intCast(i)) - 1)..@min(m, i + 2)) |x| {
                for (@max(0, @as(isize, @intCast(j)) - 1)..@min(n, j + 2)) |y| {
                    if (grid.items[x].items[y] != .Empty) {
                        paper_count_adjacent += 1;
                    }
                }
            }
            if (paper_count_adjacent <= PART1_ADJACENT_UPPER_BOUND) {
                grid.items[i].items[j] = .Lifted;
                count += 1;
            }
        }
    }

    for (0..m) |i| {
        for (0..n) |j| {
            if (grid.items[i].items[j] == .Lifted) {
                grid.items[i].items[j] = .Empty;
            }
        }
    }
    return count;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !usize {
    var grid = try parse(segments, allocator);
    defer {
        for (grid.items) |*row| {
            row.deinit(allocator);
        }
        grid.deinit(allocator);
    }

    return forklift(&grid);
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !usize {
    var grid = try parse(segments, allocator);
    defer {
        for (grid.items) |*row| {
            row.deinit(allocator);
        }
        grid.deinit(allocator);
    }

    var total: usize = 0;
    while (true) {
        const removed = forklift(&grid);
        if (removed == 0) break;
        total += removed;
    }
    return total;
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
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(13, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(43, result);
    }
}
