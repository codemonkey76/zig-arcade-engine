const std = @import("std");
const rl = @import("raylib");

pub const Logger = struct {
    file: ?std.fs.File,
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    log_level: rl.TraceLogLevel,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, filepath: []const u8, log_level: rl.TraceLogLevel) !Self {
        const file = try std.fs.cwd().createFile(filepath, .{
            .truncate = false,
            .read = true,
        });

        try file.seekFromEnd(0);

        return .{
            .file = file,
            .allocator = allocator,
            .mutex = std.Thread.Mutex{},
            .log_level = log_level,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.file) |file| {
            file.close();
        }
    }

    fn shouldLog(self: *Self, level: rl.TraceLogLevel) bool {
        return @intFromEnum(level) >= @intFromEnum(self.log_level);
    }

    fn log(self: *Self, level: rl.TraceLogLevel, comptime fmt: []const u8, args: anytype) void {
        if (!self.shouldLog(level)) return;

        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.file) |file| {
            const timestamp = std.time.timestamp();

            // Use buffered writer
            var buf: [4096]u8 = undefined;
            buf = std.mem.zeroes(u8, 4096);
            const writer = file.writer(&buf);

            writer.print("[{d}] ", .{timestamp}) catch return;
            writer.print(fmt, args) catch return;
            writer.writeByte('\n') catch return;
        }
    }

    pub fn logError(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.err, "ERROR: " ++ fmt, args);
    }

    pub fn logInfo(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.info, "INFO: " ++ fmt, args);
    }

    pub fn logDebug(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.debug, "DEBUG: " ++ fmt, args);
    }

    pub fn logTrace(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.trace, "TRACE: " ++ fmt, args);
    }

    pub fn logWarn(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.warning, "WARN: " ++ fmt, args);
    }

    pub fn logFatal(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.fatal, "FATAL: " ++ fmt, args);
    }

    pub fn setLevel(self: *Self, level: rl.TraceLogLevel) void {
        self.log_level = level;
    }
};
