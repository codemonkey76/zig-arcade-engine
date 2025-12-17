const std = @import("std");

/// Generic entity reference system that works with any entity ID type
pub fn EntityRef(comptime IdType: type, comptime TagType: type) type {
    return union(enum) {
        /// Reference a specific entity by ID
        id: IdType,
        /// Reference the first entity matching a tag/type
        tag: TagType,

        pub fn isId(self: @This()) bool {
            return self == .id;
        }

        pub fn isTag(self: @This()) bool {
            return self == .tag;
        }
    };
}

/// Simple u32 ID variant for common use
pub const EntityRefU32 = EntityRef(u32, usize);

/// Entity lookup trait - games implement this for their entity manager
pub fn EntityLookup(comptime EntityType: type, comptime RefType: type) type {
    return struct {
        pub const FindFn = *const fn (self: *anyopaque, ref: RefType) ?*EntityType;

        ptr: *anyopaque,
        findFn: FindFn,

        pub fn find(self: @This(), ref: RefType) ?*EntityType {
            return self.findFn(self.ptr, ref);
        }
    };
}

test "EntityRef types" {
    const testing = std.testing;

    const MyEntityType = enum { player, enemy };
    const MyRef = EntityRef(u32, MyEntityType);

    const ref_by_id = MyRef{ .id = 42 };
    const ref_by_tag = MyRef{ .tag = .player };

    try testing.expect(ref_by_id.isId());
    try testing.expect(!ref_by_id.isTag());
    try testing.expect(ref_by_tag.isTag());
    try testing.expect(!ref_by_tag.isId());
}
