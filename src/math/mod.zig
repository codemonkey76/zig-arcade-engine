pub const Rect = @import("rect.zig").Rect;

test {
    @import("std").testing.refAllDecls(@This());
}
