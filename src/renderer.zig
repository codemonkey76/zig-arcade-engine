const rl = @import("raylib");
const Viewport = @import("viewport.zig").Viewport;
const types = @import("root.zig").types;
const sprite_manager = @import("graphics/sprite_manager.zig");

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
        const vw = @as(f32, @floatFromInt(self.viewport.virtual_width * self.viewport.ssaa_scale));
        const vh = @as(f32, @floatFromInt(self.viewport.virtual_height * self.viewport.ssaa_scale));
        const n = types.Vec2{ .x = pos_rt.x / vw, .y = pos_rt.y / vh };
        self.drawFilledCircle(n, radius_rt, color);
    }

    pub fn drawLineRT(self: Self, a_rt: types.Vec2, b_rt: types.Vec2, thickness_rt: f32, color: types.Color) void {
        const vw = @as(f32, @floatFromInt(self.viewport.virtual_width * self.viewport.ssaa_scale));
        const vh = @as(f32, @floatFromInt(self.viewport.virtual_height * self.viewport.ssaa_scale));
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

    /// Draw a sprite at normalized coordinates (0-1)
    pub fn drawSprite(
        self: Self,
        sprite: sprite_manager.Sprite,
        normalized_pos: types.Vec2,
    ) void {
        const screen_pos = self.toScreen(normalized_pos);
        const ssaa = self.ssaaScale();

        const dest = rl.Rectangle{
            .x = screen_pos.x,
            .y = screen_pos.y,
            .width = sprite.getWidth() * ssaa,
            .height = sprite.getHeight() * ssaa,
        };

        rl.drawTexturePro(
            sprite.texture.handle,
            sprite.getSourceRect(),
            dest,
            .{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );
    }

    /// Draw a flipped sprite at normalized coordinates (0-1)
    pub fn drawFlippedSprite(
        self: Self,
        flipped: sprite_manager.FlippedSprite,
        normalized_pos: types.Vec2,
    ) void {
        const screen_pos = self.toScreen(normalized_pos);
        const ssaa = self.ssaaScale();

        var source = flipped.sprite.getSourceRect();
        if (flipped.flip.horizontal) source.width = -source.width;
        if (flipped.flip.vertical) source.height = -source.height;

        const dest = rl.Rectangle{
            .x = screen_pos.x,
            .y = screen_pos.y,
            .width = flipped.sprite.getWidth() * ssaa,
            .height = flipped.sprite.getHeight() * ssaa,
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
