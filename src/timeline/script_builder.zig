const std = @import("std");
const ActionBase = @import("action.zig").ActionBase;

/// Fluent API for building timeline scripts
///
/// Usage:
///   var builder = ScriptBuilder(MyAction).init(allocator);
///   try builder.add(0.0, 1.0, .{ .move = ... });
///   try builder.add(1.0, 2.0, .{ .shoot = ... });
///   const script = try builder.build();
pub fn ScriptBuilder(comptime ActionDataType: type) type {
    return struct {
        allocator: std.mem.Allocator,
        actions: std.ArrayList(ActionWithBase),

        const Self = @This();

        pub const ActionWithBase = struct {
            base: ActionBase,
            data: ActionDataType,
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .actions = std.ArrayList(ActionWithBase).empty,
            };
        }

        /// Add an action at a specific time with duration
        pub fn add(self: *Self, start_time: f32, duration: f32, data: ActionDataType) !void {
            try self.actions.append(self.allocator, .{
                .base = .{
                    .start_time = start_time,
                    .duration = duration,
                },
                .data = data,
            });
        }

        /// Add an action immediately after the last action
        pub fn then(self: *Self, duration: f32, data: ActionDataType) !void {
            const start_time = if (self.actions.items.len > 0) blk: {
                const last = self.actions.items[self.actions.items.len - 1];
                break :blk last.base.start_time + last.base.duration;
            } else 0.0;

            try self.add(start_time, duration, data);
        }

        /// Add an action at the same time as the previous action (parallel)
        pub fn parallel(self: *Self, duration: f32, data: ActionDataType) !void {
            const start_time = if (self.actions.items.len > 0) blk: {
                const last = self.actions.items[self.actions.items.len - 1];
                break :blk last.base.start_time;
            } else 0.0;

            try self.add(start_time, duration, data);
        }

        /// Add a delay/wait before the next action
        pub fn wait(self: *Self, duration: f32) !void {
            const start_time = if (self.actions.items.len > 0) blk: {
                const last = self.actions.items[self.actions.items.len - 1];
                break :blk last.base.start_time + last.base.duration;
            } else 0.0;

            // We add a dummy action - games should handle a "wait" action type
            // Or just use the time gap naturally
            _ = start_time;
            _ = duration;
            // This is a placeholder - actual implementation depends on game's action types
        }

        /// Get the total duration of all actions
        pub fn getTotalDuration(self: Self) f32 {
            var max: f32 = 0.0;
            for (self.actions.items) |action| {
                const end = action.base.start_time + action.base.duration;
                if (end > max) max = end;
            }
            return max;
        }

        /// Sort actions by start time (useful for sequential playback)
        pub fn sort(self: *Self) void {
            std.sort.insertion(ActionWithBase, self.actions.items, {}, compareStartTime);
        }

        fn compareStartTime(_: void, a: ActionWithBase, b: ActionWithBase) bool {
            return a.base.start_time < b.base.start_time;
        }

        /// Build the final action list
        /// Transfers ownership to caller
        pub fn build(self: *Self) ![]const ActionWithBase {
            return try self.actions.toOwnedSlice(self.allocator);
        }

        /// Clear without building (if you want to reuse the builder)
        pub fn clear(self: *Self) void {
            self.actions.clearRetainingCapacity();
        }

        pub fn deinit(self: *Self) void {
            self.actions.deinit(self.allocator);
        }
    };
}

test "ScriptBuilder basic usage" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const ActionData = union(enum) {
        move: struct { x: f32, y: f32 },
        shoot: struct { target: u32 },
    };

    var builder = ScriptBuilder(ActionData).init(allocator);
    defer builder.deinit();

    try builder.add(0.0, 1.0, .{ .move = .{ .x = 10, .y = 20 } });
    try builder.add(1.5, 0.5, .{ .shoot = .{ .target = 42 } });

    const script = try builder.build();
    defer allocator.free(script);

    try testing.expectEqual(@as(usize, 2), script.len);
    try testing.expectEqual(@as(f32, 0.0), script[0].base.start_time);
    try testing.expectEqual(@as(f32, 1.5), script[1].base.start_time);
}

test "ScriptBuilder sequential actions" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const ActionData = union(enum) {
        action: i32,
    };

    var builder = ScriptBuilder(ActionData).init(allocator);
    defer builder.deinit();

    try builder.add(0.0, 1.0, .{ .action = 1 });
    try builder.then(2.0, .{ .action = 2 });
    try builder.then(1.5, .{ .action = 3 });

    const script = try builder.build();
    defer allocator.free(script);

    try testing.expectEqual(@as(usize, 3), script.len);
    try testing.expectEqual(@as(f32, 0.0), script[0].base.start_time);
    try testing.expectEqual(@as(f32, 1.0), script[1].base.start_time); // 0.0 + 1.0
    try testing.expectEqual(@as(f32, 3.0), script[2].base.start_time); // 1.0 + 2.0
}

test "ScriptBuilder parallel actions" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const ActionData = union(enum) {
        action: i32,
    };

    var builder = ScriptBuilder(ActionData).init(allocator);
    defer builder.deinit();

    try builder.add(1.0, 2.0, .{ .action = 1 });
    try builder.parallel(1.0, .{ .action = 2 });
    try builder.parallel(3.0, .{ .action = 3 });

    const script = try builder.build();
    defer allocator.free(script);

    try testing.expectEqual(@as(usize, 3), script.len);
    // All should start at same time
    try testing.expectEqual(@as(f32, 1.0), script[0].base.start_time);
    try testing.expectEqual(@as(f32, 1.0), script[1].base.start_time);
    try testing.expectEqual(@as(f32, 1.0), script[2].base.start_time);
}
