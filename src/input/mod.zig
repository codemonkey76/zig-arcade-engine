pub const Input = @import("input.zig").Input;

test {
    @import("std").testing.refAllDecls(@This());
}
