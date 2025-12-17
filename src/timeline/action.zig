const std = @import("std");

/// Base timing information for any action
pub const ActionBase = struct {
    start_time: f32,
    duration: f32,

    /// Check if this action should be active at the given time
    pub fn isActive(self: ActionBase, time: f32) bool {
        return time >= self.start_time and time < (self.start_time + self.duration);
    }

    /// Get the progress through this action (0.0 to 1.0)
    pub fn progress(self: ActionBase, time: f32) f32 {
        if (time < self.start_time) return 0.0;
        if (time >= self.start_time + self.duration) return 1.0;
        return (time - self.start_time) / self.duration;
    }

    /// Get the progress with an easing function applied
    pub fn progressEased(self: ActionBase, time: f32, easing_fn: EasingFn) f32 {
        const t = self.progress(time);
        return easing_fn(t);
    }
};

/// Generic action that wraps timing + custom data
pub fn Action(comptime T: type) type {
    return struct {
        base: ActionBase,
        data: T,

        pub fn isActive(self: @This(), time: f32) bool {
            return self.base.isActive(time);
        }

        pub fn progress(self: @This(), time: f32) f32 {
            return self.base.progress(time);
        }
    };
}

/// Easing function signature
pub const EasingFn = *const fn (f32) f32;

test "ActionBase timing" {
    const testing = std.testing;

    const action = ActionBase{
        .start_time = 1.0,
        .duration = 2.0,
    };

    // Before start
    try testing.expect(!action.isActive(0.5));
    try testing.expectEqual(@as(f32, 0.0), action.progress(0.5));

    // At start
    try testing.expect(action.isActive(1.0));
    try testing.expectEqual(@as(f32, 0.0), action.progress(1.0));

    // Midway
    try testing.expect(action.isActive(2.0));
    try testing.expectEqual(@as(f32, 0.5), action.progress(2.0));

    // At end
    try testing.expect(!action.isActive(3.0));
    try testing.expectEqual(@as(f32, 1.0), action.progress(3.0));

    // After end
    try testing.expect(!action.isActive(4.0));
    try testing.expectEqual(@as(f32, 1.0), action.progress(4.0));
}

test "Action with custom data" {
    const testing = std.testing;

    const MoveData = struct {
        x: f32,
        y: f32,
    };

    const MoveAction = Action(MoveData);

    const action = MoveAction{
        .base = .{ .start_time = 0.0, .duration = 1.0 },
        .data = .{ .x = 100.0, .y = 200.0 },
    };

    try testing.expect(action.isActive(0.5));
    try testing.expectEqual(@as(f32, 0.5), action.progress(0.5));
    try testing.expectEqual(@as(f32, 100.0), action.data.x);
}
