const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

const ROUNDING = 100;
const POS_START = 50;

const MyError = error{
    ParseError,
};

fn part1(lines: *SegmentIterator) !i32 {
    var position: i16 = POS_START;
    var count: i16 = 0;

    while (try lines.next()) |instruction| {
        const direction = instruction[0];
        const angle_str = instruction[1..];
        const angle = try std.fmt.parseInt(i16, angle_str, 10);

        position = position + try switch (direction) {
            'L' => -angle,
            'R' => angle,
            else => MyError.ParseError,
        };
        position = @mod(position, ROUNDING);

        if (position == 0) {
            count += 1;
        }
    }
    return count;
}

fn part2(lines: *SegmentIterator) !i32 {
    var position: i16 = POS_START;
    var count: i16 = 0;

    while (try lines.next()) |instruction| {
        const direction = instruction[0];
        const angle_str = instruction[1..];
        const angle = try std.fmt.parseInt(u16, angle_str, 10);

        switch (direction) {
            'L' => {
                const new_position = position - @as(i16, @intCast(angle));
                count += @divFloor(position - 1, ROUNDING) - @divFloor(new_position + ROUNDING, ROUNDING) + 1;
                position = new_position;
            },
            'R' => {
                const new_position = position + @as(i16, @intCast(angle));
                count += @divFloor(new_position - 1, ROUNDING);
                position = new_position;
            },
            else => return MyError.ParseError,
        }

        position = @mod(position, ROUNDING);
        if (position == 0) {
            count += 1;
        }
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
        const result = try part1(&reader.iterator);
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator);
        const elapsed_ms = timer.read() / std.time.ns_per_ms;
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "secret-entrance" {
    const testcase =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator);
        try std.testing.expectEqual(3, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator);
        try std.testing.expectEqual(6, result);
    }
}
