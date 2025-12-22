const std = @import("std");
const lib = @import("arcade_lib");

pub const Path = struct {
    name: []const u8,
    anchors: []const lib.AnchorPoint,
    definition: lib.PathDefinition,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator, filename: []const u8, _: void) !Self {
        const path = try lib.Path.loadPath(allocator, filename);
        errdefer {
            allocator.free(path.name);
            allocator.free(path.anchors);
        }

        // Convert anchors to control points for PathDefinition
        const control_points = try lib.PathDefinition.fromAnchorPoints(allocator, path.anchors);

        return .{
            .name = path.name,
            .anchors = path.anchors,
            .definition = lib.PathDefinition{ .name = path.name, .control_points = control_points },
            .allocator = allocator,
        };
    }
    pub fn unload(self: *Self) void {
        self.allocator.free(self.name);
        self.allocator.free(self.anchors);
        self.allocator.free(self.definition.control_points);
    }
};
