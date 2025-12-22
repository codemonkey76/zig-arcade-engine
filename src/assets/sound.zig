const rl = @import("raylib");
const std = @import("std");

pub const Sound = struct {
    handle: rl.Sound,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator, path: []const u8, _: void) !Self {
        const path_z = try allocator.dupeZ(u8, path);
        defer allocator.free(path_z);

        const font = try rl.loadSound(path_z);
        return .{ .handle = font };
    }

    pub fn unload(self: *Self) void {
        rl.unloadSound(self.handle);
    }
};
