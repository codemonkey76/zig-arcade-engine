// Public API for the graphics subsystem

pub const Viewport = @import("viewport.zig").Viewport;
pub const Renderer = @import("renderer.zig").Renderer;
pub const Anchor = @import("renderer.zig").Anchor;
pub const TextRenderer = @import("text.zig").TextRenderer;
pub const Texture = @import("texture.zig").Texture;

const sprite_manager = @import("sprite_manager.zig");
pub const SpriteLayout = sprite_manager.SpriteLayout;
pub const SpriteLayoutBuilder = sprite_manager.SpriteLayoutBuilder;
pub const RotationSet = sprite_manager.RotationSet;
pub const RotationFrame = sprite_manager.RotationFrame;
pub const AnimationDef = sprite_manager.AnimationDef;
pub const AnimationState = sprite_manager.AnimationState;
pub const Sprite = sprite_manager.Sprite;
pub const FlippedSprite = sprite_manager.FlippedSprite;
pub const FlipMode = sprite_manager.FlipMode;

test {
    @import("std").testing.refAllDecls(@This());
}
