const std = @import("std");
const ActionBase = @import("action.zig").ActionBase;

/// Configuration for Timeline behavior
pub const TimelineConfig = struct {
    /// Whether to loop the timeline when it reaches the end
    loop: bool = false,
    /// Optional callback when timeline completes (before loop)
    on_complete: ?*const fn () void = null,
};

/// Generic timeline that executes actions over time
///
/// ActionType should be a union/enum of all possible actions for your game
/// ExecutorType should provide start() and update() methods
pub fn Timeline(
    comptime ActionType: type,
    comptime ExecutorType: type,
) type {
    return struct {
        allocator: std.mem.Allocator,
        actions: []const ActionType,
        executor: ExecutorType,
        elapsed_time: f32 = 0.0,
        active_actions: std.AutoHashMap(usize, void),
        config: TimelineConfig,

        const Self = @This();

        pub fn init(
            allocator: std.mem.Allocator,
            actions: []const ActionType,
            executor: ExecutorType,
            config: TimelineConfig,
        ) !Self {
            return .{
                .allocator = allocator,
                .actions = actions,
                .executor = executor,
                .active_actions = std.AutoHashMap(usize, void).init(allocator),
                .config = config,
            };
        }

        /// Update the timeline by dt seconds
        pub fn update(self: *Self, dt: f32) !void {
            self.elapsed_time += dt;

            // Process actions
            for (self.actions, 0..) |action, idx| {
                const action_base = self.getActionBase(action);

                if (action_base.isActive(self.elapsed_time)) {
                    // Start action if not already active
                    if (!self.active_actions.contains(idx)) {
                        try self.executor.start(action);
                        try self.active_actions.put(idx, {});
                    }

                    // Update action
                    const progress = action_base.progress(self.elapsed_time);
                    try self.executor.update(action, progress);
                }
            }

            // Check for completion
            if (self.elapsed_time >= self.getTotalDuration()) {
                if (self.config.on_complete) |callback| {
                    callback();
                }

                if (self.config.loop) {
                    try self.reset();
                }
            }
        }

        /// Reset the timeline to the beginning
        pub fn reset(self: *Self) !void {
            self.elapsed_time = 0.0;
            self.active_actions.clearRetainingCapacity();
            try self.executor.reset();
        }

        /// Get the total duration of the timeline
        pub fn getTotalDuration(self: Self) f32 {
            var max: f32 = 0.0;
            for (self.actions) |action| {
                const base = self.getActionBase(action);
                const end = base.start_time + base.duration;
                if (end > max) max = end;
            }
            return max;
        }

        /// Get current time as percentage of total duration
        pub fn getProgress(self: Self) f32 {
            const total = self.getTotalDuration();
            if (total == 0.0) return 1.0;
            return self.elapsed_time / total;
        }

        /// Check if timeline is complete (not applicable if looping)
        pub fn isComplete(self: Self) bool {
            return self.elapsed_time >= self.getTotalDuration();
        }

        /// Seek to a specific time in the timeline
        /// Note: This doesn't re-execute actions, it just sets the time
        pub fn seekTo(self: *Self, time: f32) void {
            self.elapsed_time = time;
            // Could optionally re-execute all actions up to this point
        }

        fn getActionBase(self: Self, action: ActionType) ActionBase {
            _ = self;
            // This assumes ActionType has a .base field
            // Games can customize this by wrapping Timeline
            return action.base;
        }

        pub fn deinit(self: *Self) void {
            self.active_actions.deinit();
            self.executor.deinit();
        }
    };
}

test "Timeline basic flow" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Simple action type for testing
    const TestAction = struct {
        base: ActionBase,
        value: i32,
    };

    // Simple executor for testing
    const TestExecutor = struct {
        allocator: std.mem.Allocator,
        started: std.ArrayList(i32),
        updated: std.ArrayList(i32),

        pub fn init(alloc: std.mem.Allocator) @This() {
            return .{
                .allocator = alloc,
                .started = std.ArrayList(i32).empty,
                .updated = std.ArrayList(i32).empty,
            };
        }

        pub fn start(self: *@This(), action: TestAction) !void {
            try self.started.append(self.allocator, action.value);
        }

        pub fn update(self: *@This(), action: TestAction, progress: f32) !void {
            _ = progress;
            try self.updated.append(self.allocator, action.value);
        }

        pub fn reset(self: *@This()) !void {
            self.started.clearRetainingCapacity();
            self.updated.clearRetainingCapacity();
        }

        pub fn deinit(self: *@This()) void {
            self.started.deinit(self.allocator);
            self.updated.deinit(self.allocator);
        }
    };

    const TimelineType = Timeline(TestAction, TestExecutor);

    var actions = [_]TestAction{
        .{ .base = .{ .start_time = 0.0, .duration = 1.0 }, .value = 1 },
        .{ .base = .{ .start_time = 0.5, .duration = 1.0 }, .value = 2 },
    };

    var executor = TestExecutor.init(allocator);
    defer executor.deinit();

    var timeline = try TimelineType.init(
        allocator,
        &actions,
        executor,
        .{ .loop = false },
    );
    defer timeline.deinit();

    // Initial state
    try testing.expectEqual(@as(f32, 0.0), timeline.elapsed_time);
    try testing.expectEqual(@as(f32, 1.5), timeline.getTotalDuration());

    // After 0.25s - only first action active
    try timeline.update(0.25);
    try testing.expectEqual(@as(usize, 1), timeline.executor.started.items.len);

    // After 0.75s - both actions active
    try timeline.update(0.5);
    try testing.expectEqual(@as(usize, 2), timeline.executor.started.items.len);
}
