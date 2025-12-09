const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn Range(comptime T: type) type {
    return struct {
        start: T,
        end: T,

        pub fn merges(self: Range(T), other: Range(T)) ?Range(T) {
            if (self.end < other.start or other.end < self.start) {
                return null;
            }
            return Range(T){
                .start = @min(self.start, other.start),
                .end = @max(self.end, other.end),
            };
        }

        pub fn contains(self: Range(T), value: T) bool {
            return self.start <= value and value <= self.end;
        }

        pub fn lessThan(context: void, a: Range(T), b: Range(T)) bool {
            _ = context;
            return a.start < b.start;
        }
    };
}

fn Database(comptime T: type) type {
    return struct {
        ranges: std.ArrayList(Range(T)),
        available: std.ArrayList(T),

        pub fn parse(segments: *SegmentIterator, allocator: std.mem.Allocator) !Database(T) {
            var self = Database(T){
                .ranges = try std.ArrayList(Range(T)).initCapacity(allocator, 16),
                .available = try std.ArrayList(T).initCapacity(allocator, 16),
            };

            while (try segments.next()) |segment| {
                if (segment.len == 0) {
                    break;
                }
                var parts = std.mem.splitScalar(u8, segment, '-');
                const start = try std.fmt.parseInt(T, parts.first(), 10);
                const end = try std.fmt.parseInt(T, parts.next().?, 10);

                try self.ranges.append(allocator, Range(T){ .start = start, .end = end });
            }

            while (try segments.next()) |segment| {
                if (segment.len == 0) {
                    break;
                }
                const value = try std.fmt.parseInt(T, segment, 10);
                try self.available.append(allocator, value);
            }

            return self;
        }

        pub fn deinit(self: *Database(T), allocator: std.mem.Allocator) void {
            self.ranges.deinit(allocator);
            self.available.deinit(allocator);
        }
    };
}

fn merge(ranges: []Range(u64), allocator: std.mem.Allocator) !std.ArrayList(Range(u64)) {
    std.mem.sort(Range(u64), ranges, {}, Range(u64).lessThan);

    var merged_ranges: std.ArrayList(Range(u64)) = try std.ArrayList(Range(u64)).initCapacity(allocator, ranges.len);

    var merged: Range(u64) = ranges[0];
    for (ranges[1..]) |range| {
        if (merged.merges(range)) |new_merged| {
            merged = new_merged;
        } else {
            try merged_ranges.append(allocator, merged);
            merged = range;
        }
    }
    try merged_ranges.append(allocator, merged);
    return merged_ranges;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var db = try Database(u64).parse(segments, allocator);
    defer db.deinit(allocator);

    const available = db.available.items;
    std.mem.sort(u64, available, {}, std.sort.asc(u64));

    var merged_ranges = try merge(db.ranges.items, allocator);
    defer merged_ranges.deinit(allocator);

    var count: u64 = 0;
    var idx: usize = 0;
    outer: for (available) |value| {
        while (idx < merged_ranges.items.len) : (idx += 1) {
            const range = merged_ranges.items[idx];
            if (value < range.start) continue :outer;
            if (range.contains(value)) {
                count += 1;
                continue :outer;
            }
        }
    }
    return count;
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var db = try Database(u64).parse(segments, allocator);
    defer db.deinit(allocator);

    var merged_ranges = try merge(db.ranges.items, allocator);
    defer merged_ranges.deinit(allocator);

    var count: u64 = 0;
    for (merged_ranges.items) |range| {
        count += range.end - range.start + 1;
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
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(3, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(14, result);
    }
}
