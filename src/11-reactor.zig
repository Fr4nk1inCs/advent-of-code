const std = @import("std");

const utils = @import("utils.zig");
const getInputFile = utils.getInputFile;
const SegmentIterator = utils.SegmentIterator;
const FileSegmentReader = utils.FileSegmentReader;
const BufferSegmentReader = utils.BufferSegmentReader;

// Names are fixed-length 3-byte sequences
// We treat them as u32 for easier comparison and hashing
const NAME_LEN = 3;
const Name = [NAME_LEN]u8;
inline fn toName(s: []const u8) Name {
    var name: Name = undefined;
    @memcpy(&name, s[0..NAME_LEN]);
    return name;
}

const YOU: Name = Name{ 'y', 'o', 'u' };
const OUT: Name = Name{ 'o', 'u', 't' };
const SVR: Name = Name{ 's', 'v', 'r' };
const FFT: Name = Name{ 'f', 'f', 't' };
const DAC: Name = Name{ 'd', 'a', 'c' };

const EMPTY_ADJ: [0]*Node = [_]*Node{};

const Node = struct {
    adj: []*Node,

    pub fn alloc(allocator: std.mem.Allocator) !*Node {
        var node = try allocator.create(Node);
        node.adj = &EMPTY_ADJ;
        return node;
    }

    pub fn free(self: *Node, allocator: std.mem.Allocator) void {
        if (self.adj.ptr != &EMPTY_ADJ) {
            allocator.free(self.adj);
        }
        allocator.destroy(self);
    }
};

const Graph = struct {
    nodes: std.AutoHashMap(Name, *Node),

    pub fn init(allocator: std.mem.Allocator) Graph {
        return Graph{
            .nodes = std.AutoHashMap(Name, *Node).init(allocator),
        };
    }

    pub fn deinit(self: *Graph, allocator: std.mem.Allocator) void {
        var it = self.nodes.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.free(allocator);
        }
        self.nodes.deinit();
    }

    inline fn getOrCreate(self: *Graph, allocator: std.mem.Allocator, name: Name) !*Node {
        return if (self.nodes.contains(name))
            self.nodes.get(name).?
        else create_node: {
            const tmp = try Node.alloc(allocator);
            try self.nodes.put(name, tmp);
            break :create_node tmp;
        };
    }

    // Each line is of the form: src: dst dst ...
    pub fn parse(allocator: std.mem.Allocator, lines: *SegmentIterator) !Graph {
        var graph = Graph.init(allocator);
        while (try lines.next()) |line| {
            const src = toName(line[0..NAME_LEN]);
            const other = line[NAME_LEN + 2 ..]; // skip ": "

            const num_adj = @divExact(other.len + 1, NAME_LEN + 1);

            var node = try graph.getOrCreate(allocator, src);
            node.adj = try allocator.alloc(*Node, num_adj);
            for (0..num_adj, node.adj) |i, *adj_ptr| {
                const start = i * (NAME_LEN + 1);
                const name = toName(other[start .. start + NAME_LEN]);
                adj_ptr.* = try graph.getOrCreate(allocator, name);
            }
        }
        return graph;
    }
};

fn CountedQueue(comptime T: type, comptime C: type) type {
    return struct {
        const Self = @This();

        const Counted = struct {
            item: T,
            count: C,
        };

        array: std.ArrayList(Counted),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .array = try std.ArrayList(Counted).initCapacity(allocator, 32),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit(self.allocator);
        }

        pub fn append(self: *Self, item: T, count: C) !void {
            for (self.array.items) |*existing| {
                if (existing.item == item) {
                    existing.count += count;
                    return;
                }
            }
            try self.array.append(self.allocator, Counted{
                .item = item,
                .count = count,
            });
        }

        pub fn pop(self: *Self) ?Counted {
            if (self.array.items.len == 0) return null;
            return self.array.orderedRemove(0);
        }
    };
}

fn bfs(allocator: std.mem.Allocator, start: *Node, goal: *Node) !u64 {
    var queue = try CountedQueue(*Node, u64).init(allocator);
    defer queue.deinit();

    var count: u64 = 0;
    try queue.append(start, 1);
    while (queue.pop()) |entry| {
        if (entry.item == goal) {
            count += entry.count;
            continue;
        }

        for (entry.item.adj) |neighbor| {
            try queue.append(neighbor, entry.count);
        }
    }
    return count;
}

fn part1(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var graph = try Graph.parse(allocator, segments);
    defer graph.deinit(allocator);
    const start = graph.nodes.get(YOU).?;
    const goal = graph.nodes.get(OUT).?;
    return try bfs(allocator, start, goal);
}

fn part2(segments: *SegmentIterator, allocator: std.mem.Allocator) !u64 {
    var graph = try Graph.parse(allocator, segments);
    defer graph.deinit(allocator);

    const svr = graph.nodes.get(SVR).?;
    const fft = graph.nodes.get(FFT).?;
    const dac = graph.nodes.get(DAC).?;
    const out = graph.nodes.get(OUT).?;

    const fft2dac = try bfs(allocator, fft, dac);
    if (fft2dac != 0) {
        const svr2fft = try bfs(allocator, svr, fft);
        const dac2out = try bfs(allocator, dac, out);
        return svr2fft * dac2out * fft2dac;
    }

    const dac2fft = try bfs(allocator, dac, fft);
    if (dac2fft != 0) {
        const svr2dac = try bfs(allocator, svr, dac);
        const fft2out = try bfs(allocator, fft, out);
        return svr2dac * fft2out * dac2fft;
    }

    return 0;
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
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 1: {} ({} ms)\n", .{ result, elapsed_ms });
    }

    {
        var reader = try FileSegmentReader.init(&input_file, &read_buf, allocator, '\n');
        defer reader.deinit();
        var timer = try std.time.Timer.start();
        const result = try part2(&reader.iterator, allocator);
        const elapsed_ms = (timer.read() / std.time.ns_per_ms);
        std.debug.print("Part 2: {} ({} ms)\n", .{ result, elapsed_ms });
    }
}

test "aoc-test" {
    const testcase1 =
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
    ;
    const testcase2 =
        \\svr: aaa bbb
        \\aaa: fft
        \\fft: ccc
        \\bbb: tty
        \\tty: ccc
        \\ccc: ddd eee
        \\ddd: hub
        \\hub: fff
        \\eee: dac
        \\dac: fff
        \\fff: ggg hhh
        \\ggg: out
        \\hhh: out
    ;
    const allocator = std.testing.allocator;

    {
        var reader = try BufferSegmentReader.init(testcase1, allocator, '\n');
        defer reader.deinit();
        const result = try part1(&reader.iterator, allocator);
        try std.testing.expectEqual(5, result);
    }

    {
        var reader = try BufferSegmentReader.init(testcase2, allocator, '\n');
        defer reader.deinit();
        const result = try part2(&reader.iterator, allocator);
        try std.testing.expectEqual(2, result);
    }
}
