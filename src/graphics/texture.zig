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
    ) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const texture = try rl.loadTexture(path_z);
        if (texture.id == 0) {
            return error.TextureLoadFailed;
        }

        return .{ .handle = texture };
    }
};
