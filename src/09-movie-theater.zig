const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn rectArea(a: Point(T), b: Point(T)) T {
            return (udiff(T, a.x, b.x) + 1) * (udiff(T, a.y, b.y) + 1);
        }
    };
}

fn udiff(comptime T: type, a: T, b: T) T {
    return if (a > b) a - b else b - a;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var points = try std.ArrayList(Point(u64)).initCapacity(allocator, 16);
    defer points.deinit(allocator);

    var max_area: u64 = 0;

    while (try segments.next()) |segment| {
        var parts = std.mem.splitScalar(u8, segment, ',');
        const x = try std.fmt.parseInt(u64, parts.next().?, 10);
        const y = try std.fmt.parseInt(u64, parts.next().?, 10);

        const point = Point(u64){ .x = x, .y = y };

        for (points.items) |other_point| {
            const area = Point(u64).rectArea(point, other_point);
            if (area > max_area) {
                max_area = area;
            }
        }

        try points.append(allocator, point);
    }

    return max_area;
}

const Tile = enum(u2) {
    Colored,
    Border,
    Clear,
};

pub fn Range(comptime T: type) type {
    return struct {
        start: T,
        end: T,
    };
}

fn VLine(comptime T: type) type {
    return struct {
        x: T,
        ys: Range(T),

        pub fn init(x: T, y_start: T, y_end: T) VLine(T) {
            return VLine(T){
                .x = x,
                .ys = Range(T){ .start = y_start, .end = y_end },
            };
        }

        fn lessThan(context: void, a: VLine(T), b: VLine(T)) bool {
            _ = context;
            return a.x < b.x;
        }

        fn rel(context: Range(T), line: VLine(T)) Rel {
            if (line.x <= context.start) {
                return .Before;
            } else if (line.x >= context.end) {
                return .After;
            } else {
                return .Inside;
            }
        }
    };
}

fn HLine(comptime T: type) type {
    return struct {
        y: T,
        xs: Range(T),

        pub fn init(y: T, x_start: T, x_end: T) HLine(T) {
            return HLine(T){
                .y = y,
                .xs = Range(T){ .start = x_start, .end = x_end },
            };
        }

        fn lessThan(context: void, a: HLine(T), b: HLine(T)) bool {
            _ = context;
            return a.y < b.y;
        }

        fn rel(context: Range(T), line: HLine(T)) Rel {
            if (line.y <= context.start) {
                return .Before;
            } else if (line.y >= context.end) {
                return .After;
            } else {
                return .Inside;
            }
        }
    };
}

fn Borders(comptime T: type) type {
    return struct {
        horizontal: []HLine(T),
        vertical: []VLine(T),
    };
}

fn GridView(comptime T: type) type {
    return struct {
        width: T,
        height: T,
        borders: Borders(T),
        _hlines: std.ArrayList(HLine(T)),
        _vlines: std.ArrayList(VLine(T)),

        pub fn init(allocator: std.mem.Allocator, points: []const Point(T)) !GridView(T) {
            var max_x: T = 0;
            var max_y: T = 0;

            var hlines = try std.ArrayList(HLine(T)).initCapacity(allocator, 16);
            var vlines = try std.ArrayList(VLine(T)).initCapacity(allocator, 16);

            for (0..points.len) |i| {
                const p = points[i];
                const q = points[(i + 1) % points.len];

                max_x = @max(max_x, p.x);
                max_y = @max(max_y, p.y);

                if (p.x == q.x) {
                    try vlines.append(allocator, VLine(T).init(p.x, @min(p.y, q.y), @max(p.y, q.y)));
                } else if (p.y == q.y) {
                    try hlines.append(allocator, HLine(T).init(p.y, @min(p.x, q.x), @max(p.x, q.x)));
                } else {
                    unreachable;
                }
            }

            std.mem.sort(VLine(T), vlines.items, {}, VLine(T).lessThan);
            std.mem.sort(HLine(T), hlines.items, {}, HLine(T).lessThan);

            return GridView(T){
                .width = max_x + 1,
                .height = max_y + 1,
                .borders = Borders(T){
                    .horizontal = hlines.items,
                    .vertical = vlines.items,
                },
                ._hlines = hlines,
                ._vlines = vlines,
            };
        }

        pub fn deinit(self: *GridView(T), allocator: std.mem.Allocator) void {
            self._hlines.deinit(allocator);
            self._vlines.deinit(allocator);
        }
    };
}

const Rel = enum {
    Before,
    Inside,
    After,
};

fn SortedSlicedIterator(comptime T: type, comptime ContextT: type, comptime RelFn: fn (context: ContextT, item: T) Rel) type {
    return struct {
        sorted: []const T,
        index: usize,
        context: ContextT,

        pub fn init(sorted: []const T, context: ContextT) SortedSlicedIterator(T, ContextT, RelFn) {
            return SortedSlicedIterator(T, ContextT, RelFn){
                .sorted = sorted,
                .index = findStart(sorted, context),
                .context = context,
            };
        }

        fn findStart(sorted: []const T, context: ContextT) usize {
            var low: usize = 0;
            var high: usize = sorted.len;

            while (low < high) {
                const mid = (low + high) / 2;
                switch (RelFn(context, sorted[mid])) {
                    .Before => low = mid + 1,
                    .Inside, .After => high = mid,
                }
            }

            return low;
        }

        pub fn next(self: *SortedSlicedIterator(T, ContextT, RelFn)) ?T {
            if (self.index >= self.sorted.len) return null;

            const item = self.sorted[self.index];
            switch (RelFn(self.context, item)) {
                .Before => unreachable,
                .Inside => {
                    self.index += 1;
                    return item;
                },
                .After => return null,
            }
        }
    };
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var points = try std.ArrayList(Point(u64)).initCapacity(allocator, 16);
    defer points.deinit(allocator);

    while (try segments.next()) |segment| {
        var parts = std.mem.splitScalar(u8, segment, ',');
        const x = try std.fmt.parseInt(u64, parts.next().?, 10);
        const y = try std.fmt.parseInt(u64, parts.next().?, 10);
        try points.append(allocator, Point(u64){ .x = x, .y = y });
    }

    var grid = try GridView(u64).init(allocator, points.items);
    defer grid.deinit(allocator);

    var max_area: u64 = 0;
    for (0..points.items.len, points.items) |i, p| {
        update: for (points.items[i + 1 ..]) |q| {
            const x_start = @min(p.x, q.x);
            const x_end = @max(p.x, q.x);
            const y_start = @min(p.y, q.y);
            const y_end = @max(p.y, q.y);

            {
                var vlines = SortedSlicedIterator(VLine(u64), Range(u64), VLine(u64).rel).init(
                    grid.borders.vertical,
                    Range(u64){ .start = x_start, .end = x_end },
                );

                while (vlines.next()) |vline| {
                    if (vline.ys.start <= y_start and vline.ys.end > y_start) continue :update;
                    if (vline.ys.start < y_end and vline.ys.end >= y_end) continue :update;
                }
            }

            {
                var hlines = SortedSlicedIterator(HLine(u64), Range(u64), HLine(u64).rel).init(
                    grid.borders.horizontal,
                    Range(u64){ .start = y_start, .end = y_end },
                );

                while (hlines.next()) |hline| {
                    if (hline.xs.start <= x_start and hline.xs.end > x_start) continue :update;
                    if (hline.xs.start < x_end and hline.xs.end >= x_end) continue :update;
                }
            }

            max_area = @max(max_area, Point(u64).rectArea(p, q));
        }
    }
    return max_area;
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
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(50, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(24, result);
    }
}
