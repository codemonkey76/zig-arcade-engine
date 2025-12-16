const rl = @import("raylib");
const Viewport = @import("viewport.zig").Viewport;
const types = @import("root.zig").types;
const sprite_manager = @import("graphics/sprite_manager.zig");

/// Sprite anchor/origin point (normalized 0-1 within sprite bounds)
pub const Anchor = struct {
    x: f32,
    y: f32,

    pub const top_left = Anchor{ .x = 0.0, .y = 0.0 };
    pub const top_center = Anchor{ .x = 0.5, .y = 0.0 };
    pub const top_right = Anchor{ .x = 1.0, .y = 0.0 };
    pub const center_left = Anchor{ .x = 0.0, .y = 0.5 };
    pub const center = Anchor{ .x = 0.5, .y = 0.5 };
    pub const center_right = Anchor{ .x = 1.0, .y = 0.5 };
    pub const bottom_left = Anchor{ .x = 0.0, .y = 1.0 };
    pub const bottom_center = Anchor{ .x = 0.5, .y = 1.0 };
    pub const bottom_right = Anchor{ .x = 1.0, .y = 1.0 };
};

pub const Renderer = struct {
    viewport: *const Viewport,

    const Self = @This();

    pub fn init(viewport: *const Viewport) Self {
        return .{
            .viewport = viewport,
        };
    }

    /// Convert normalized coordinates (0-1) to screen coordinates
    pub fn toScreen(self: *const Self, normalized: types.Vec2) types.Vec2 {
        return self.viewport.normalizedToScreen(normalized);
    }

    /// Get SSAA scale factor
    fn ssaaScale(self: Self) f32 {
        return @as(f32, @floatFromInt(self.viewport.ssaa_scale));
    }

    /// Get sprite width in normalized coordinates (0-1)
    pub fn spriteWidth(self: Self, sprite: sprite_manager.Sprite) f32 {
        const vw = @as(f32, @floatFromInt(self.viewport.virtual_width));
        return sprite.getWidth() / vw;
    }

    /// Get sprite height in normalized coordinates (0-1)
    pub fn spriteHeight(self: Self, sprite: sprite_manager.Sprite) f32 {
        const vh = @as(f32, @floatFromInt(self.viewport.virtual_height));
        return sprite.getHeight() / vh;
    }

    /// Get flipped sprite width in normalized coordinates (0-1)
    pub fn flippedSpriteWidth(self: Self, flipped: sprite_manager.FlippedSprite) f32 {
        const vw = @as(f32, @floatFromInt(self.viewport.virtual_width));
        return flipped.sprite.getWidth() / vw;
    }

    /// Get flipped sprite height in normalized coordinates (0-1)
    pub fn flippedSpriteHeight(self: Self, flipped: sprite_manager.FlippedSprite) f32 {
        const vh = @as(f32, @floatFromInt(self.viewport.virtual_height));
        return flipped.sprite.getHeight() / vh;
    }

    /// Draw a line at normalized coordinates (0-1) with thickness
    pub fn drawLine(
        self: Self,
        start: types.Vec2,
        end: types.Vec2,
        thickness: f32,
        color: types.Color,
    ) void {
        const screen_start = self.toScreen(start);
        const screen_end = self.toScreen(end);

        rl.drawLineEx(screen_start, screen_end, thickness, color);
    }

    /// Draw a circle at normalized coordinates (0-1)
    pub fn drawFilledCircle(self: Self, pos: types.Vec2, radius: f32, color: types.Color) void {
        const screen_pos = self.toScreen(pos);
        rl.drawCircleV(screen_pos, radius, color);
    }
    pub fn drawFilledCircleRT(self: Self, pos_rt: types.Vec2, radius_rt: f32, color: types.Color) void {
        const vw = @as(f32, @floatFromInt(@as(u64, self.viewport.virtual_width) * @as(u64, self.viewport.ssaa_scale)));
        const vh = @as(f32, @floatFromInt(@as(u64, self.viewport.virtual_height) * @as(u64, self.viewport.ssaa_scale)));
        const n = types.Vec2{ .x = pos_rt.x / vw, .y = pos_rt.y / vh };
        self.drawFilledCircle(n, radius_rt, color);
    }

    pub fn drawLineRT(self: Self, a_rt: types.Vec2, b_rt: types.Vec2, thickness_rt: f32, color: types.Color) void {
        const vw = @as(f32, @floatFromInt(@as(u64, self.viewport.virtual_width) * @as(u64, self.viewport.ssaa_scale)));
        const vh = @as(f32, @floatFromInt(@as(u64, self.viewport.virtual_height) * @as(u64, self.viewport.ssaa_scale)));
        const a_n = types.Vec2{ .x = a_rt.x / vw, .y = a_rt.y / vh };
        const b_n = types.Vec2{ .x = b_rt.x / vw, .y = b_rt.y / vh };
        self.drawLine(a_n, b_n, thickness_rt, color);
    }

    /// Draw a circle outline at normalized coordinates (0-1) with thickness
    pub fn drawCircle(
        self: Self,
        pos: types.Vec2,
        radius: f32,
        thickness: f32,
        color: types.Color,
    ) void {
        const screen_pos = self.toScreen(pos);
        const segments: i32 = @intFromFloat(@max(12, @min(64, radius / 2.0)));

        rl.drawRing(
            screen_pos,
            radius - thickness / 2.0,
            radius + thickness / 2.0,
            0.0,
            360.0,
            segments,
            color,
        );
    }

    /// Draw a sprite at normalized coordinates (0-1) with center anchor
    pub fn drawSprite(
        self: Self,
        sprite: sprite_manager.Sprite,
        normalized_pos: types.Vec2,
    ) void {
        self.drawSpriteAnchored(sprite, normalized_pos, Anchor.center);
    }

    /// Draw a sprite at normalized coordinates (0-1) with custom anchor
    pub fn drawSpriteAnchored(
        self: Self,
        sprite: sprite_manager.Sprite,
        normalized_pos: types.Vec2,
        anchor: Anchor,
    ) void {
        const screen_pos = self.toScreen(normalized_pos);
        const ssaa = self.ssaaScale();

        const width = sprite.getWidth() * ssaa;
        const height = sprite.getHeight() * ssaa;

        const dest = rl.Rectangle{
            .x = screen_pos.x,
            .y = screen_pos.y,
            .width = width,
            .height = height,
        };

        const origin = rl.Vector2{
            .x = width * anchor.x,
            .y = height * anchor.y,
        };

        rl.drawTexturePro(
            sprite.texture.handle,
            sprite.getSourceRect(),
            dest,
            origin,
            0.0,
            rl.Color.white,
        );
    }

    /// Draw a flipped sprite at normalized coordinates (0-1) with center anchor
    pub fn drawFlippedSprite(
        self: Self,
        flipped: sprite_manager.FlippedSprite,
        normalized_pos: types.Vec2,
    ) void {
        self.drawFlippedSpriteAnchored(flipped, normalized_pos, Anchor.center);
    }

    /// Draw a flipped sprite at normalized coordinates (0-1) with custom anchor
    pub fn drawFlippedSpriteAnchored(
        self: Self,
        flipped: sprite_manager.FlippedSprite,
        normalized_pos: types.Vec2,
        anchor: Anchor,
    ) void {
        const screen_pos = self.toScreen(normalized_pos);
        const ssaa = self.ssaaScale();

        var source = flipped.sprite.getSourceRect();
        if (flipped.flip.horizontal) source.width = -source.width;
        if (flipped.flip.vertical) source.height = -source.height;

        const width = flipped.sprite.getWidth() * ssaa;
        const height = flipped.sprite.getHeight() * ssaa;

        const dest = rl.Rectangle{
            .x = screen_pos.x,
            .y = screen_pos.y,
            .width = width,
            .height = height,
        };

        const origin = rl.Vector2{
            .x = width * anchor.x,
            .y = height * anchor.y,
        };

        rl.drawTexturePro(
            flipped.sprite.texture.handle,
            source,
            dest,
            origin,
            0.0,
            rl.Color.white,
        );
    }

    /// Draw a rectangle outline at normalized coordinates (0-1)
    pub fn drawRectangleLines(
        self: Self,
        rect: types.Rect,
        thickness: f32,
        color: types.Color,
    ) void {
        const top_left = self.toScreen(.{ .x = rect.x, .y = rect.y });
        const ssaa = self.ssaaScale();

        const screen_rect = rl.Rectangle{
            .x = top_left.x,
            .y = top_left.y,
            .width = rect.width * self.viewport.virtual_width * ssaa,
            .height = rect.height * self.viewport.virtual_height * ssaa,
        };

        rl.drawRectangleLinesEx(screen_rect, thickness * ssaa, color);
    }

    /// Draw a filled rectangle at normalized coordinates (0-1)
    pub fn drawRectangle(
        self: Self,
        rect: types.Rect,
        color: types.Color,
    ) void {
        const top_left = self.toScreen(.{ .x = rect.x, .y = rect.y });
        const ssaa = self.ssaaScale();

        const screen_rect = rl.Rectangle{
            .x = top_left.x,
            .y = top_left.y,
            .width = rect.width * @as(f32, @floatFromInt(self.viewport.virtual_width)) * ssaa,
            .height = rect.height * @as(f32, @floatFromInt(self.viewport.virtual_height)) * ssaa,
        };

        rl.drawRectangleRec(screen_rect, color);
    }
};
