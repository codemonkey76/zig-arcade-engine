// engine/src/root.zig
const std = @import("std");
const rl = @import("raylib");

// Re-export core types
pub const Config = @import("core/config.zig").Config;
pub const Context = @import("core/context.zig").Context;
pub const GameVTable = @import("core/run.zig").GameVTable;
pub const run = @import("core/run.zig").run;

// Re-export common types from raylib
pub const types = struct {
    pub const Vec2 = rl.Vector2;
    pub const Color = rl.Color;
    pub const Rect = rl.Rectangle;
    pub const TraceLogLevel = rl.TraceLogLevel;
};

// Subsystem modules
pub const graphics = @import("graphics/mod.zig");
pub const timeline = @import("timeline/mod.zig");
pub const math = @import("math/mod.zig");

// Convenience re-exports for common types
pub const Renderer = graphics.Renderer;
pub const Anchor = graphics.Anchor;

pub const input = @import("input/mod.zig");
pub const assets = @import("assets/mod.zig");

test {
    std.testing.refAllDecls(@This());
}
