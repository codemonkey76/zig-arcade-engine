// Public API for the timeline / cutscene system
pub const Timeline = @import("timeline.zig").Timeline;
pub const Action = @import("action.zig").Action;
pub const ActionBase = @import("action.zig").ActionBase;
pub const EntityRef = @import("entity_ref.zig").EntityRef;
pub const ScriptBuilder = @import("script_builder.zig").ScriptBuilder;
pub const easing = @import("easing.zig");

// Example implementations shoing how to use the timeline system
pub const examples = struct {
    pub const simple_demo = @import("examples/simple_demo.zig");
};

test {
    @import("std").testing.refAllDecls(@This());
}
