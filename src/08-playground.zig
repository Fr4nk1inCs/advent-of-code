const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

fn Pos(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub fn parse(repr: []const u8) !Pos(T) {
            var tokens = std.mem.splitScalar(u8, repr, ',');
            const x = try std.fmt.parseInt(T, tokens.next().?, 10);
            const y = try std.fmt.parseInt(T, tokens.next().?, 10);
            const z = try std.fmt.parseInt(T, tokens.next().?, 10);
            return Pos(T){ .x = x, .y = y, .z = z };
        }
    };
}

fn uabs(comptime T: type, a: T, b: T) T {
    return if (a > b) a - b else b - a;
}

fn IdxPair(comptime T: type) type {
    return struct {
        a: usize,
        b: usize,
        distance: T,

        pub fn cmp(context: void, self: IdxPair(T), other: IdxPair(T)) std.math.Order {
            _ = context;
            return std.math.order(self.distance, other.distance);
        }
    };
}

pub fn DisjointSet(comptime T: type) type {
    return struct {
        parent: []T,
        sizes: []T,

        pub fn init(allocator: std.mem.Allocator, capacity: T) !DisjointSet(T) {
            const parent = try allocator.alloc(T, capacity);
            const sizes = try allocator.alloc(T, capacity);
            for (parent, 0..capacity) |*p, i| {
                p.* = @as(T, @intCast(i));
            }
            @memset(sizes, 1);
            return DisjointSet(T){
                .parent = parent,
                .sizes = sizes,
            };
        }

        pub fn find(self: *DisjointSet(T), x: T) T {
            if (self.parent[x] != x) {
                self.parent[x] = self.find(self.parent[x]);
            }
            return self.parent[x];
        }

        pub fn unite(self: *DisjointSet(T), a: T, b: T) void {
            var pa_a = self.find(a);
            var pa_b = self.find(b);
            if (pa_a == pa_b) return;
            if (self.sizes[pa_a] < self.sizes[pa_b]) std.mem.swap(T, &pa_a, &pa_b);
            self.parent[pa_b] = pa_a;
            self.sizes[pa_a] += self.sizes[pa_b];
        }

        pub fn deinit(self: *DisjointSet(T), allocator: std.mem.Allocator) void {
            allocator.free(self.parent);
            allocator.free(self.sizes);
        }
    };
}

fn part1(segments: *SegmentIterator, cables: u16, allocator: std.mem.Allocator) !u16 {
    const Box = Pos(u64);
    const BoxPair = IdxPair(u64);

    var boxes = try std.ArrayList(Box).initCapacity(allocator, 16);
    defer boxes.deinit(allocator);
    while (try segments.next()) |segment| {
        try boxes.append(allocator, try Box.parse(segment));
    }

    var box_pairs = std.PriorityDequeue(BoxPair, void, BoxPair.cmp).init(allocator, {});
    defer box_pairs.deinit();
    try box_pairs.ensureTotalCapacity(cables + 1);

    for (0..boxes.items.len, boxes.items) |i, *box_a| {
        for (i + 1..boxes.items.len, boxes.items[i + 1 ..]) |j, *box_b| {
            const dx = uabs(u64, box_a.x, box_b.x);
            const dy = uabs(u64, box_a.y, box_b.y);
            const dz = uabs(u64, box_a.z, box_b.z);
            const pair = BoxPair{
                .a = i,
                .b = j,
                .distance = dx * dx + dy * dy + dz * dz,
            };
            try box_pairs.add(pair);
            if (box_pairs.len > cables) {
                _ = box_pairs.removeMax();
            }
        }
    }

    var circuits = try DisjointSet(u16).init(allocator, @as(u16, @intCast(boxes.items.len)));
    defer circuits.deinit(allocator);

    for (0..cables) |_| {
        const pair = box_pairs.removeMin();
        circuits.unite(@as(u16, @intCast(pair.a)), @as(u16, @intCast(pair.b)));
    }

    const Vec3 = @Vector(3, u16);
    var top3: Vec3 = .{ 1, 1, 1 };
    for (0..circuits.parent.len, circuits.parent, circuits.sizes) |i, parent, size| {
        if (i != parent) continue;
        if (size > top3[0]) {
            top3[2] = top3[1];
            top3[1] = top3[0];
            top3[0] = size;
        } else if (size > top3[1]) {
            top3[2] = top3[1];
            top3[1] = size;
        } else if (size > top3[2]) {
            top3[2] = size;
        }
    }

    return top3[0] * top3[1] * top3[2];
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    const Box = Pos(u64);
    const BoxPair = IdxPair(u64);

    var boxes = try std.ArrayList(Box).initCapacity(allocator, 16);
    defer boxes.deinit(allocator);
    while (try segments.next()) |segment| {
        try boxes.append(allocator, try Box.parse(segment));
    }

    var box_pairs = std.PriorityDequeue(BoxPair, void, BoxPair.cmp).init(allocator, {});
    defer box_pairs.deinit();
    try box_pairs.ensureTotalCapacity(boxes.items.len * (boxes.items.len - 1) / 2);

    for (0..boxes.items.len, boxes.items) |i, *box_a| {
        for (i + 1..boxes.items.len, boxes.items[i + 1 ..]) |j, *box_b| {
            const dx = uabs(u64, box_a.x, box_b.x);
            const dy = uabs(u64, box_a.y, box_b.y);
            const dz = uabs(u64, box_a.z, box_b.z);
            const pair = BoxPair{
                .a = i,
                .b = j,
                .distance = dx * dx + dy * dy + dz * dz,
            };
            try box_pairs.add(pair);
        }
    }

    var circuits = try DisjointSet(u16).init(allocator, @as(u16, @intCast(boxes.items.len)));
    defer circuits.deinit(allocator);

    var pair: BoxPair = undefined;
    while (true) {
        pair = box_pairs.removeMin();
        const a = @as(u16, @intCast(pair.a));
        const b = @as(u16, @intCast(pair.b));
        circuits.unite(a, b);

        if (circuits.sizes[circuits.find(a)] == boxes.items.len) {
            return boxes.items[pair.a].x * boxes.items[pair.b].x;
        }
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
        const result = try part1(&reader.iterator, 1000, allocator);
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
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, 10, allocator);
        try std.testing.expectEqual(40, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual({}, result);
    }
}
