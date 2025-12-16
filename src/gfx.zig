const rl = @import("raylib");
const types = @import("root.zig").types;

pub const Gfx = struct {
    pub fn drawLine(start: types.Vec2, end: types.Vec2, color: types.Color) void {
        rl.drawLineV(start, end, color);
    }
    pub fn drawCircle(start: types.Vec2, radius: f32, color: types.Color) void {
        rl.drawCircleV(start, radius, color);
    }
};
