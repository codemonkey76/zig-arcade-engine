const std = @import("std");

pub const AssetManager = struct {
    allocator: std.mem.Allocator,
    asset_root: []const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, asset_root: []const u8) !Self {
        return .{
            .allocator = allocator,
            .asset_root = asset_root,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};
