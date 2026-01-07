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
            self.file = null;
        }
    }

    fn shouldLog(self: *Self, level: rl.TraceLogLevel) bool {
        return @intFromEnum(level) >= @intFromEnum(self.log_level);
    }

    fn log(self: *Self, level: rl.TraceLogLevel, comptime fmt: []const u8, args: anytype) void {
        if (!self.shouldLog(level)) return;

        self.mutex.lock();
        defer self.mutex.unlock();

        const timestamp = std.time.timestamp();
        const level_str = switch (level) {
            .all => "ALL",
            .trace => "TRACE",
            .debug => "DEBUG",
            .info => "INFO",
            .warning => "WARN",
            .err => "ERROR",
            .fatal => "FATAL",
            .none => "NONE",
        };

        if (self.file) |file| {
            // Format timestamp
            const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
            const epoch_day = epoch_seconds.getEpochDay();
            const year_day = epoch_day.calculateYearDay();
            const month_day = year_day.calculateMonthDay();
            const day_seconds = epoch_seconds.getDaySeconds();

            var msg_buf: [3096]u8 = undefined;
            const user_msg = std.fmt.bufPrint(&msg_buf, fmt, args) catch "ERROR FORMATTING";

            var log_buf: [4096]u8 = undefined;
            const message = std.fmt.bufPrint(&log_buf, "[{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}] {s}: {s}\n", .{
                year_day.year,
                month_day.month.numeric(),
                month_day.day_index + 1,
                day_seconds.getHoursIntoDay(),
                day_seconds.getMinutesIntoHour(),
                day_seconds.getSecondsIntoMinute(),
                level_str,
                user_msg,
            }) catch return;

            file.writeAll(message) catch return;
        }
    }

    pub fn err(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.err, fmt, args);
    }

    pub fn info(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.info, fmt, args);
    }

    pub fn debug(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.debug, fmt, args);
    }

    pub fn trace(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.trace, fmt, args);
    }

    pub fn warn(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.warning, fmt, args);
    }

    pub fn fatal(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log(.fatal, fmt, args);
    }

    pub fn setLevel(self: *Self, level: rl.TraceLogLevel) void {
        self.log_level = level;
    }
};
