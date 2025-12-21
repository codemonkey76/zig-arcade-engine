const std = @import("std");
const lib = @import("arcade_lib");

pub const Path = struct {
    name: []const u8,
    anchors: []lib.AnchorPoint,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator, filename: []const u8, _: void) !Self {
        const path = try lib.Path.loadPath(allocator, filename);
        return .{
            .name = path.name,
            .anchors = path.anchors,
        };
    }
    pub fn unload(self: Self) void {
        _ = self;
    }
};
