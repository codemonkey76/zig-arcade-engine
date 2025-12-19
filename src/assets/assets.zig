const std = @import("std");
const rl = @import("raylib");
const Texture = @import("../graphics/texture.zig").Texture;

pub const AssetManager = struct {
    allocator: std.mem.Allocator,
    asset_root: []const u8,
    textures: std.StringHashMap(Texture),
    fonts: std.StringHashMap(rl.Font),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, asset_root: []const u8) !Self {
        return .{
            .allocator = allocator,
            .asset_root = asset_root,
            .textures = std.StringHashMap(Texture).init(allocator),
            .fonts = std.StringHashMap(rl.Font).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.textures.iterator();
        while (it.next()) |entry| {
            rl.unloadTexture(entry.value_ptr.handle);
            self.allocator.free(entry.key_ptr.*);
        }
        self.textures.deinit();

        var font_it = self.fonts.iterator();
        while (font_it.next()) |entry| {
            rl.unloadFont(entry.value_ptr.*);
            self.allocator.free(entry.key_ptr.*);
        }
        self.fonts.deinit();
    }

    pub fn loadTexture(self: *Self, filename: []const u8, transparent_color: ?rl.Color) !Texture {
        if (self.textures.get(filename)) |texture| {
            return texture;
        }

        const full_path = try std.fs.path.join(self.allocator, &.{ self.asset_root, filename });
        defer self.allocator.free(full_path);

        const texture = try Texture.loadFromFile(self.allocator, full_path, transparent_color);

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

    pub fn loadFont(self: *Self, filename: []const u8) !rl.Font {
        if (self.fonts.get(filename)) |font| {
            return font;
        }

        const full_path = try std.fs.path.join(self.allocator, &.{ self.asset_root, filename });
        defer self.allocator.free(full_path);

        // Create null-terminated string for C
        const path_z = try self.allocator.dupeZ(u8, full_path);
        defer self.allocator.free(path_z);

        const font = try rl.loadFont(path_z);

        const key = try self.allocator.dupe(u8, filename);
        errdefer self.allocator.free(key);

        try self.fonts.put(key, font);

        return font;
    }

    pub fn getFont(self: *Self, filename: []const u8) ?rl.Font {
        return self.fonts.get(filename);
    }

    pub fn unloadFont(self: *Self, filename: []const u8) void {
        if (self.fonts.fetchRemove(filename)) |entry| {
            rl.unloadFont(entry.value);
            self.allocator.free(entry.key);
        }
    }
};
