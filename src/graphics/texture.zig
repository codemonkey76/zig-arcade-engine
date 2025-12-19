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

    /// Load a texture from a file
    pub fn loadFromFile(
        allocator: std.mem.Allocator,
        path: []const u8,
        transparent_color: ?rl.Color,
    ) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        var texture: rl.Texture2D = undefined;

        if (transparent_color) |color| {
            var image: rl.Image = try rl.loadImage(path_z);
            defer rl.unloadImage(image);
            // Ensure image has alpha channel before color replacement
            rl.imageFormat(&image, rl.PixelFormat.uncompressed_r8g8b8a8);
            rl.imageColorReplace(&image, color, .{ .r = 0, .g = 0, .b = 0, .a = 0 });
            texture = try rl.loadTextureFromImage(image);
        } else {
            texture = try rl.loadTexture(path_z);
        }

        if (texture.id == 0) {
            return error.TextureLoadFailed;
        }

        // Use point filtering to avoid black borders from bilinear interpolation with transparent pixels
        rl.setTextureFilter(texture, rl.TextureFilter.point);

        return .{ .handle = texture };
    }
};
