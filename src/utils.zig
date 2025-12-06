const std = @import("std");

fn print_help_and_exit() void {
    const prog = std.os.argv[0];
    std.debug.print("Usage: {s} <input_file>\n", .{prog});
    std.process.exit(0);
}

pub fn get_input_file() !std.fs.File {
    if (std.os.argv.len < 2) {
        print_help_and_exit();
    }

    const arg = std.mem.sliceTo(std.os.argv[1], 0);
    if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
        print_help_and_exit();
    }
    return try std.fs.cwd().openFile(arg, .{ .mode = .read_only });
}

pub const SegmentIterator = struct {
    reader: *std.Io.Reader,
    writer: *std.Io.Writer.Allocating,
    delimiter: u8 = '\n',

    pub fn next(self: *SegmentIterator) !?[]u8 {
        const bytes = try self.reader.streamDelimiterEnding(&self.writer.writer, self.delimiter);
        const end = try self.eos();
        if (bytes == 0 and end)
            return null;
        if (!end) {
            _ = try self.reader.takeByte();
        }

        const segment = self.writer.written();
        self.writer.clearRetainingCapacity();
        return segment;
    }

    pub fn eos(self: *SegmentIterator) !bool {
        _ = self.reader.peekByte() catch |err| switch (err) {
            error.EndOfStream => return true,
            else => return err,
        };
        return false;
    }
};

pub const FileSegmentReader = struct {
    file: *std.fs.File,
    reader: *std.fs.File.Reader,
    writer: *std.Io.Writer.Allocating,
    iterator: SegmentIterator,
    allocator: std.mem.Allocator,

    pub fn init(file: *std.fs.File, buffer: []u8, allocator: std.mem.Allocator, delimiter: u8) !FileSegmentReader {
        try file.seekTo(0);

        const reader = try allocator.create(std.fs.File.Reader);
        reader.* = file.readerStreaming(buffer);

        const writer = try allocator.create(std.Io.Writer.Allocating);
        writer.* = std.Io.Writer.Allocating.init(allocator);

        return FileSegmentReader{
            .file = file,
            .reader = reader,
            .writer = writer,
            .iterator = SegmentIterator{
                .reader = &reader.interface,
                .writer = writer,
                .delimiter = delimiter,
            },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FileSegmentReader) void {
        self.writer.deinit();
        self.allocator.destroy(self.reader);
        self.allocator.destroy(self.writer);
    }
};

pub const BufferSegmentReader = struct {
    buffer: []const u8,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer.Allocating,
    iterator: SegmentIterator,
    allocator: std.mem.Allocator,

    pub fn init(buffer: []const u8, allocator: std.mem.Allocator, delimiter: u8) !BufferSegmentReader {
        const reader = try allocator.create(std.Io.Reader);
        reader.* = std.Io.Reader.fixed(buffer);

        const writer = try allocator.create(std.Io.Writer.Allocating);
        writer.* = std.Io.Writer.Allocating.init(allocator);

        return BufferSegmentReader{
            .buffer = buffer,
            .reader = reader,
            .writer = writer,
            .iterator = SegmentIterator{
                .reader = reader,
                .writer = writer,
                .delimiter = delimiter,
            },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BufferSegmentReader) void {
        self.writer.deinit();
        self.allocator.destroy(self.reader);
        self.allocator.destroy(self.writer);
    }
};
