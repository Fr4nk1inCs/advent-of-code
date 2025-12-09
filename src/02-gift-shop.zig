const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

inline fn exp10(n: usize) u64 {
    var result: u64 = 1;
    for (0..n) |_| {
        result *= 10;
    }
    return result;
}

const Range = struct {
    start: u64,
    end: u64,
    len: usize,
};

/// Breaks xx-xxx style ranges into two parts: xx-99 and 100-xxx
const RangeIterator = struct {
    segments: *SegmentIterator,
    cur_comp: bool = true,
    cur_start: u64 = 0,
    cur_end: u64 = 0,
    cur_len: usize = 0,

    pub fn next(self: *RangeIterator) !?Range {
        if (!self.cur_comp) {
            self.cur_comp = true;
            return Range{
                .start = exp10(self.cur_len),
                .end = self.cur_end,
                .len = self.cur_len + 1,
            };
        }

        const next_seg = try self.segments.next();
        if (next_seg == null) return null;

        const trimmed = std.mem.trim(u8, next_seg.?, "\n\r");
        var splitted = std.mem.splitScalar(u8, trimmed, '-');

        const start_repr = splitted.first();
        const end_repr = splitted.next().?;

        self.cur_start = try std.fmt.parseInt(u64, start_repr, 10);
        self.cur_end = try std.fmt.parseInt(u64, end_repr, 10);
        self.cur_len = start_repr.len;
        if (self.cur_len != end_repr.len) {
            self.cur_comp = false;
            return Range{
                .start = self.cur_start,
                .end = exp10(self.cur_len) - 1,
                .len = self.cur_len,
            };
        } else {
            self.cur_comp = true;
            return Range{
                .start = self.cur_start,
                .end = self.cur_end,
                .len = self.cur_len,
            };
        }
    }
};

fn part1(segments: *SegmentIterator) !u64 {
    var sum: u64 = 0;
    var ranges = RangeIterator{ .segments = segments };

    while (try ranges.next()) |range| {
        const start = range.start;
        const end = range.end;
        const len = range.len;

        if (len % 2 != 0) {
            continue;
        }

        const lol = exp10(len / 2) + 1;
        const min_val = @divFloor(start + lol - 1, lol);
        const max_val = @divFloor(end, lol);
        for (min_val..(max_val + 1)) |i| {
            sum += i * lol;
        }
    }
    return sum;
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var sum: u64 = 0;
    var ranges = RangeIterator{ .segments = segments };

    var invalid_ids = std.AutoHashMap(u64, void).init(allocator);
    defer invalid_ids.deinit();

    while (try ranges.next()) |range| {
        const start = range.start;
        const end = range.end;
        const len = range.len;

        for (2..(len + 1)) |parts| {
            if (len % parts != 0) continue;
            const sublen = len / parts;

            var lols: u64 = 1;
            for (1..parts) |_| {
                lols = lols * exp10(sublen) + 1;
            }

            const min_val = @divFloor(start + lols - 1, lols);
            const max_val = @divFloor(end, lols);
            for (min_val..(max_val + 1)) |i| {
                const invalid_id = i * lols;
                if (invalid_ids.contains(invalid_id)) {
                    continue;
                }
                try invalid_ids.put(invalid_id, {});
                sum += i * lols;
            }
        }
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
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, ',');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part1(&reader.iterator);
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, ',');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator, allocator);
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "aoc-test" {
    const testcase =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
        \\1698522-1698528,446443-446449,38593856-38593862,565653-565659,
        \\824824821-824824827,2121212118-2121212124
        \\
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, ',');
        defer reader.deinit();
        const result = try part1(&reader.iterator);
        try std.testing.expectEqual(1227775554, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, ',');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(4174379265, result);
    }
}
