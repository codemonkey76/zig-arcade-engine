const std = @import("std");
const rl = @import("raylib");
pub const Config = @import("config.zig").Config;
pub const Context = @import("context.zig").Context;
pub const GameVTable = @import("run.zig").GameVTable;
pub const Gfx = @import("gfx.zig").Gfx;

pub const types = struct {
    pub const Vec2 = rl.Vector2;
    pub const Color = rl.Color;
    pub const Rect = rl.Rectangle;
    pub const TraceLogLevel = rl.TraceLogLevel;
};

pub const graphics = struct {
    const sm = @import("graphics/sprite_manager.zig");
    pub const SpriteLayoutBuilder = sm.SpriteLayoutBuilder;
    pub const RotationSet = sm.RotationSet;
    pub const RotationFrame = sm.RotationFrame;
    pub const SpriteLayout = sm.SpriteLayout;
};

pub const run = @import("run.zig").run;
