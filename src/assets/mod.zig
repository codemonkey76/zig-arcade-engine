pub const AssetManager = @import("assets.zig").AssetManager;

test {
    @import("std").testing.refAllDecls(@This());
}
