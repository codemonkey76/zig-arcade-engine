const std = @import("std");
const rl = @import("raylib");

pub const Texture = struct {
    handle: rl.Texture2D,

    const Self = @This();

    pub fn width(self: Self) u32 {
        return @intCast(self.handle.width);
    }

    pub fn height(self: Self) u32 {
        return @intCast(self.handle.height);
    }

    pub fn load(allocator: std.mem.Allocator, path: []const u8, transparent_color: ?rl.Color) !Self {
        return if (transparent_color) |color|
            try Self.loadWithTransparency(allocator, path, color)
        else
            try Self.loadBasic(allocator, path);
    }

    pub fn loadBasic(allocator: std.mem.Allocator, path: []const u8) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const texture = try rl.loadTexture(path_z);
        rl.setTextureFilter(texture, rl.TextureFilter.point);
        return .{ .handle = texture };
    }

    pub fn loadWithTransparency(
        allocator: std.mem.Allocator,
        path: []const u8,
        transparent_color: rl.Color,
    ) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        var image: rl.Image = try rl.loadImage(path_z);
        defer rl.unloadImage(image);
        // Ensure image has alpha channel before color replacement
        rl.imageFormat(&image, rl.PixelFormat.uncompressed_r8g8b8a8);
        rl.imageColorReplace(&image, transparent_color, .{ .r = 0, .g = 0, .b = 0, .a = 0 });
        const texture = try rl.loadTextureFromImage(image);

        if (texture.id == 0) {
            return error.TextureLoadFailed;
        }

        rl.setTextureFilter(texture, rl.TextureFilter.point);

        return .{ .handle = texture };
    }

    pub fn unload(self: *Self) void {
        rl.unloadTexture(self.handle);
    }
};
