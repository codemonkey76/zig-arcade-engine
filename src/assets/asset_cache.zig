const std = @import("std");
const Path = @import("../math/path.zig").Path;

pub fn AssetCache(
    comptime KeyType: type,
    comptime T: type,
    comptime ExtraParam: type,
    comptime loadFn: fn (std.mem.Allocator, []const u8, ExtraParam) anyerror!T,
    comptime unloadFn: ?fn (*T) void,
) type {
    return struct {
        cache: std.AutoHashMap(KeyType, T),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .cache = std.AutoHashMap(KeyType, T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.cache.valueIterator();
            while (it.next()) |value_ptr| {
                if (unloadFn) |unloadFunc| {
                    unloadFunc(value_ptr);
                }
            }

            self.cache.deinit();
        }

        pub fn load(
            self: *Self,
            allocator: std.mem.Allocator,
            asset_root: []const u8,
            key: KeyType,
            filename: []const u8,
            extra: ExtraParam,
        ) !T {
            if (self.cache.get(key)) |item| {
                return item;
            }

            const full_path = try std.fs.path.join(allocator, &.{ asset_root, filename });
            defer allocator.free(full_path);

            const item = try loadFn(allocator, full_path, extra);

            try self.cache.put(key, item);
            return item;
        }

        pub fn get(self: *Self, key: KeyType) ?T {
            return self.cache.get(key);
        }

        pub fn unload(self: *Self, key: KeyType) void {
            if (self.cache.fetchRemove(key)) |kv| {
                if (unloadFn) |unloadFunc| {
                    var item = kv.value;
                    unloadFunc(&item);
                }
            }
        }
    };
}
