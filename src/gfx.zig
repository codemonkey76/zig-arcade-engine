const rl = @import("raylib");
const types = @import("root.zig").types;
const sprite_manager = @import("graphics/sprite_manager.zig");

pub const Gfx = struct {
    pub fn drawLine(start: types.Vec2, end: types.Vec2, color: types.Color) void {
        rl.drawLineV(start, end, color);
    }
    pub fn drawCircle(start: types.Vec2, radius: f32, color: types.Color) void {
        rl.drawCircleV(start, radius, color);
    }

    /// Draw a flipped sprite (in screen coordinates)
    pub fn drawFlippedSprite(flipped: sprite_manager.FlippedSprite, pos: types.Vec2) void {
        var source = flipped.sprite.getSourceRect();
        if (flipped.flip.horizontal) source.width = -source.width;
        if (flipped.flip.vertical) source.height = -source.height;

        const dest = rl.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = flipped.sprite.getWidth(),
            .height = flipped.sprite.getHeight(),
        };

        rl.drawTexturePro(
            flipped.sprite.texture.handle,
            source,
            dest,
            .{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );
    }
};
