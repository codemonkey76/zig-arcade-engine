const std = @import("std");
const rl = @import("raylib");

pub const Font = struct {
    handle: rl.Font,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator, path: []const u8, size: ?i32) !Self {
        return if (size) |s|
            try Self.loadWithSize(allocator, path, s)
        else
            try Self.loadBasic(allocator, path);
    }

    pub fn loadBasic(allocator: std.mem.Allocator, path: []const u8) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const font = try rl.loadFont(path_z);
        return .{ .handle = font };
    }

    pub fn loadWithSize(allocator: std.mem.Allocator, path: []const u8, size: i32) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        // Load extended Latin characters (0-255) to support symbols like ©, ®, etc.
        const codepoints = try allocator.alloc(i32, 256);
        defer allocator.free(codepoints);

        for (codepoints, 0..) |*cp, i| {
            cp.* = @intCast(i);
        }

        const font = try rl.loadFontEx(path_z, size, codepoints);
        return .{ .handle = font };
    }

    pub fn unload(self: *Self) void {
        rl.unloadFont(self.handle);
    }
};
