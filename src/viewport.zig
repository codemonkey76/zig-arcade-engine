const std = @import("std");
const rl = @import("raylib");

pub const Viewport = struct {
    // Virtual resolution (your game's fixed resolution)
    virtual_width: u32,
    virtual_height: u32,

    // SSAA multiplier (e.g., 2 = render at 2x resolution)
    ssaa_scale: u32,

    // Render texture (at virtual_resolution * ssaa_scale)
    render_texture: rl.RenderTexture2D,

    // Destination rectangle in window space (for centered/scaled renderering)
    dest_rect: rl.Rectangle,

    const Self = @This();

    pub fn init(virtual_width: u32, virtual_height: u32, ssaa_scale: u32) !Self {
        const render_width = virtual_width * ssaa_scale;
        const render_height = virtual_height * ssaa_scale;

        const render_texture = try rl.loadRenderTexture(
            @intCast(render_width),
            @intCast(render_height),
        );
        return .{
            .virtual_width = virtual_width,
            .virtual_height = virtual_height,
            .ssaa_scale = ssaa_scale,
            .render_texture = render_texture,
            .dest_rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
        };
    }

    pub fn deinit(self: *Self) void {
        rl.unloadRenderTexture(self.render_texture);
    }

    // Call this when window is resized to recalculate the viewport
    pub fn updateDestRect(self: *Self, window_width: u32, window_height: u32) void {
        const virtual_aspect = @as(f32, @floatFromInt(self.virtual_width)) /
            @as(f32, @floatFromInt(self.virtual_height));

        const window_aspect = @as(f32, @floatFromInt(window_width)) /
            @as(f32, @floatFromInt(window_height));

        var scale: f32 = undefined;
        var width: f32 = undefined;
        var height: f32 = undefined;

        if (window_aspect > virtual_aspect) {
            // Window is wider - fit to height
            scale = @as(f32, @floatFromInt(window_height)) /
                @as(f32, @floatFromInt(self.virtual_height));
            height = @floatFromInt(window_height);
            width = @as(f32, @floatFromInt(self.virtual_width)) * scale;
        } else {
            // Window is taller - fit to width
            scale = @as(f32, @floatFromInt(window_width)) /
                @as(f32, @floatFromInt(self.virtual_width));
            width = @floatFromInt(window_width);
            height = @as(f32, @floatFromInt(self.virtual_height)) * scale;
        }

        // Center the viewport
        const x = (@as(f32, @floatFromInt(window_width)) - width) / 2.0;
        const y = (@as(f32, @floatFromInt(window_height)) - height) / 2.0;

        self.dest_rect = .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    /// Begin rendering to the render texture
    pub fn beginRender(self: *Self) void {
        rl.beginTextureMode(self.render_texture);
        rl.clearBackground(rl.Color.black);
    }

    /// End rendering to the render texture
    pub fn endRender(_: *Self) void {
        rl.endTextureMode();
    }

    /// Draw the render texture to the window
    pub fn draw(self: *const Self) void {
        const source = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.render_texture.texture.width),
            .height = -@as(f32, @floatFromInt(self.render_texture.texture.height)),
        };

        rl.drawTexturePro(
            self.render_texture.texture,
            source,
            self.dest_rect,
            rl.Vector2{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );
    }

    /// Convert window coordinates to virtual coordinated (for input)
    pub fn screenToVirtual(self: *const Self, screen_x: f32, screen_y: f32) ?rl.Vector2 {
        // Check if point is within viewport bounds
        if (screen_x < self.dest_rect.x or
            screen_x > self.dest_rect.x + self.dest_rect.width or
            screen_y < self.dest_rect.y or
            screen_y > self.dest_rect.y + self.dest_rect.height)
        {
            return null;
        }

        // Convert to viewport local coordinates
        const local_x = screen_x - self.dest_rect.x;
        const local_y = screen_y - self.dest_rect.y;

        // Scale to virtual coordinates
        const virt_x = (local_x / self.dest_rect.width) * @as(f32, @floatFromInt(self.virtual_width));
        const virt_y = (local_y / self.dest_rect.height) * @as(f32, @floatFromInt(self.virtual_height));

        return rl.Vector2{ .x = virt_x, .y = virt_y };
    }

    /// Convert normalized coordinates (0-1) to screen coordinates
    pub fn normalizedToScreen(self: *const Self, normalized: rl.Vector2) rl.Vector2 {
        const vw = @as(f32, @floatFromInt(self.virtual_width * self.ssaa_scale));
        const vh = @as(f32, @floatFromInt(self.virtual_height * self.ssaa_scale));

        return .{
            .x = normalized.x * vw,
            .y = normalized.y * vh,
        };
    }

    /// Convert screen coordinates to normalized coordinates (0-1)
    pub fn screenToNormalized(self: *const Self, screen: rl.Vector2) rl.Vector2 {
        const vw = @as(f32, @floatFromInt(self.virtual_width * self.ssaa_scale));
        const vh = @as(f32, @floatFromInt(self.virtual_height * self.ssaa_scale));

        return .{
            .x = screen.x / vw,
            .y = screen.y / vh,
        };
    }
};
