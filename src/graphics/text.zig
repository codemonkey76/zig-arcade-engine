const std = @import("std");
const rl = @import("raylib");
const types = @import("../root.zig").types;
const Viewport = @import("viewport.zig").Viewport;

pub const TextRenderer = struct {
    viewport: *const Viewport,
    font: ?rl.Font,

    const Self = @This();

    pub fn init(viewport: *const Viewport) Self {
        return .{ .viewport = viewport, .font = null };
    }

    pub fn setFont(self: *Self, font: ?rl.Font) void {
        self.font = font;
    }

    /// Draw text at normalized coordinates (0-1)
    pub fn drawText(
        self: Self,
        text: []const u8,
        pos: types.Vec2,
        font_size: f32,
        color: types.Color,
    ) void {
        const screen_pos = self.viewport.normalizedToScreen(pos);
        const ssaa = @as(f32, @floatFromInt(self.viewport.ssaa_scale));
        const scaled_size: i32 = @intFromFloat(font_size * ssaa);

        // Need to create null-terminated string for C
        var buf: [256:0]u8 = undefined;
        if (text.len >= buf.len) return; // Text too long

        @memcpy(buf[0..text.len], text);
        buf[text.len] = 0;

        const c_text: [:0]const u8 = buf[0..text.len :0];

        if (self.font) |font| {
            rl.drawTextEx(
                font,
                c_text,
                .{ .x = screen_pos.x, .y = screen_pos.y },
                @floatFromInt(scaled_size),
                1.0, // spacing
                color,
            );
        } else {
            rl.drawText(
                c_text,
                @intFromFloat(screen_pos.x),
                @intFromFloat(screen_pos.y),
                scaled_size,
                color,
            );
        }
    }

    /// Draw text centered horizontally at y position
    pub fn drawTextCentered(
        self: Self,
        text: []const u8,
        y: f32,
        font_size: f32,
        color: types.Color,
    ) void {
        const width = self.measureText(text, font_size);
        const x = 0.5 - (width / 2.0);
        self.drawText(text, .{ .x = x, .y = y }, font_size, color);
    }

    /// Draw text right-aligned at position
    pub fn drawTextRightAligned(
        self: Self,
        text: []const u8,
        pos: types.Vec2,
        font_size: f32,
        color: types.Color,
    ) void {
        const width = self.measureText(text, font_size);
        const x = pos.x - width;
        self.drawText(text, .{ .x = x, .y = pos.y }, font_size, color);
    }

    /// Measure text width in normalized coordinates (0-1)
    pub fn measureText(self: Self, text: []const u8, font_size: f32) f32 {
        const ssaa = @as(f32, @floatFromInt(self.viewport.ssaa_scale));
        const scaled_size: i32 = @intFromFloat(font_size * ssaa);

        var buf: [256:0]u8 = undefined;
        if (text.len >= buf.len) return 0.0;

        @memcpy(buf[0..text.len], text);
        buf[text.len] = 0;

        const c_text: [:0]const u8 = buf[0..text.len :0];

        const width_px = if (self.font) |font|
            rl.measureTextEx(font, c_text, @floatFromInt(scaled_size), 1.0).x
        else
            @as(f32, @floatFromInt(rl.measureText(c_text, scaled_size)));

        const vw = @as(f32, @floatFromInt(self.viewport.virtual_width));
        return width_px / (vw * ssaa);
    }

    /// Get font height in normalized coordinates for given font size
    pub fn getFontHeight(self: Self, font_size: f32) f32 {
        const ssaa = @as(f32, @floatFromInt(self.viewport.ssaa_scale));
        const vh = @as(f32, @floatFromInt(self.viewport.virtual_height));
        return (font_size * ssaa) / (vh * ssaa);
    }

    /// Draw text in a grid system (useful for arcade games with fixed character layouts)
    /// Grid is defined by number of columns and rows
    /// Each cell is (1.0 / cols) x (1.0 / rows) in normalized space
    pub fn drawTextGrid(
        self: Self,
        text: []const u8,
        col: u32,
        row: u32,
        cols: u32,
        rows: u32,
        font_size: f32,
        color: types.Color,
    ) void {
        const cell_width = 1.0 / @as(f32, @floatFromInt(cols));
        const cell_height = 1.0 / @as(f32, @floatFromInt(rows));

        const x = @as(f32, @floatFromInt(col)) * cell_width;
        const y = @as(f32, @floatFromInt(row)) * cell_height;

        self.drawText(text, .{ .x = x, .y = y }, font_size, color);
    }

    /// Draw text centered in a grid row
    pub fn drawTextGridCentered(
        self: Self,
        text: []const u8,
        row: u32,
        rows: u32,
        font_size: f32,
        color: types.Color,
    ) void {
        const cell_height = 1.0 / @as(f32, @floatFromInt(rows));
        const y = @as(f32, @floatFromInt(row)) * cell_height;
        self.drawTextCentered(text, y, font_size, color);
    }

    /// Draw text right-aligned in grid coordinates
    pub fn drawTextGridRightAligned(
        self: Self,
        text: []const u8,
        col: u32,
        row: u32,
        cols: u32,
        rows: u32,
        font_size: f32,
        color: types.Color,
    ) void {
        const cell_width = 1.0 / @as(f32, @floatFromInt(cols));
        const cell_height = 1.0 / @as(f32, @floatFromInt(rows));

        const x = @as(f32, @floatFromInt(col + 1)) * cell_width; // Right edge of cell
        const y = @as(f32, @floatFromInt(row)) * cell_height;

        self.drawTextRightAligned(text, .{ .x = x, .y = y }, font_size, color);
    }
};
