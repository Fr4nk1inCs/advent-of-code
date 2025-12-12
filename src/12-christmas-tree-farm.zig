const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

const PRESENT_KINDS = 6;
const PRESENT_SCALE = 3;

const Present = struct {
    shape: [PRESENT_SCALE][PRESENT_SCALE]bool,
    count: u4,

    pub fn parse(segment: *SegmentIterator) !Present {
        var shape: [PRESENT_SCALE][PRESENT_SCALE]bool = undefined;

        // ignore first line
        _ = try segment.next();

        var idx: usize = 0;
        var count: u4 = 0;
        while (idx < PRESENT_SCALE) : (idx += 1) {
            const line = (try segment.next()).?;
            var col_idx: usize = 0;
            while (col_idx < PRESENT_SCALE) : (col_idx += 1) {
                const elem = switch (line[col_idx]) {
                    '#' => true,
                    '.' => false,
                    else => return error.InvalidCharacter,
                };
                shape[idx][col_idx] = elem;
                count += @intFromBool(elem);
            }
        }

        return Present{
            .shape = shape,
            .count = count,
        };
    }
};

const Region = struct {
    width: u32,
    height: u32,
    quantities: [PRESENT_KINDS]u32,

    pub fn parse(line: []const u8) !Region {
        var tokens = std.mem.splitScalar(u8, line, ' ');
        var shape_repr = tokens.next().?;

        var shape_iter = std.mem.splitScalar(u8, shape_repr[0 .. shape_repr.len - 1], 'x');
        const width = try std.fmt.parseInt(u32, shape_iter.next().?, 10);
        const height = try std.fmt.parseInt(u32, shape_iter.next().?, 10);

        var quantities: [PRESENT_KINDS]u32 = undefined;
        for (&quantities) |*qty| {
            const token = tokens.next().?;
            qty.* = try std.fmt.parseInt(u32, token, 10);
        }

        return Region{
            .width = width,
            .height = height,
            .quantities = quantities,
        };
    }

    pub fn definitelyFits(self: *const Region) bool {
        const max_blocks: u32 = @divFloor(self.width, PRESENT_SCALE) * @divFloor(self.height, PRESENT_SCALE);
        var total_required: u32 = 0;
        for (self.quantities) |qty| {
            total_required += qty;
        }
        return total_required <= max_blocks;
    }
};

fn part1(segments: *SegmentIterator) !u32 {
    var presents: [PRESENT_KINDS]Present = undefined;
    for (&presents) |*present| {
        present.* = try Present.parse(segments);
        _ = try segments.next(); // consume empty line
    }

    var count: u32 = 0;
    while (try segments.next()) |segment| {
        const region = try Region.parse(segment);
        count += @intFromBool(region.definitelyFits());
    }
    return count;
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
        var timer = try std.time.Timer.start();
        const result = try part1(&reader.iterator);
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator);
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "aoc-test" {
    const testcase =
        \\0:
        \\###
        \\##.
        \\##.
        \\
        \\1:
        \\###
        \\##.
        \\.##
        \\
        \\2:
        \\.##
        \\###
        \\##.
        \\
        \\3:
        \\##.
        \\###
        \\##.
        \\
        \\4:
        \\###
        \\#..
        \\###
        \\
        \\5:
        \\###
        \\.#.
        \\###
        \\
        \\4x4: 0 0 0 0 2 0
        \\12x5: 1 0 1 0 2 2
        \\12x5: 1 0 1 0 3 2
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator);
        try std.testing.expectEqual(2, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator);
        try std.testing.expectEqual({}, result);
    }
}
