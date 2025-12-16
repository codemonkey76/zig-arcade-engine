const std = @import("std");
const rl = @import("raylib");
const Texture = @import("graphics/texture.zig").Texture;

pub const AssetManager = struct {
    allocator: std.mem.Allocator,
    asset_root: []const u8,
    textures: std.StringHashMap(Texture),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, asset_root: []const u8) !Self {
        return .{
            .allocator = allocator,
            .asset_root = asset_root,
            .textures = std.StringHashMap(Texture).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.textures.iterator();
        while (it.next()) |entry| {
            rl.unloadTexture(entry.value_ptr.handle);
            self.allocator.free(entry.key_ptr.*);
        }
        self.textures.deinit();
    }

    pub fn loadTexture(self: *Self, filename: []const u8) !Texture {
        if (self.textures.get(filename)) |texture| {
            return texture;
        }

        const full_path = try std.fs.path.join(self.allocator, &.{ self.asset_root, filename });
        defer self.allocator.free(full_path);

        const texture = try Texture.loadFromFile(full_path);

        const key = try self.allocator.dupe(u8, filename);
        errdefer self.allocator.free(key);

        try self.textures.put(key, texture);

        return texture;
    }

    pub fn getTexture(self: *Self, filename: []const u8) ?Texture {
        return self.textures.get(filename);
    }

    pub fn unloadTexture(self: *Self, filename: []const u8) void {
        if (self.textures.fetchRemove(filename)) |entry| {
            rl.unloadTexture(entry.value.handle);
            self.allocator.free(entry.key);
        }
    }
};
