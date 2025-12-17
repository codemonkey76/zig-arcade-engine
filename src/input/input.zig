// engine/src/input/input.zig
const rl = @import("raylib");

pub const Input = struct {
    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    // Keyboard - Key State
    pub fn isKeyDown(self: Self, key: rl.KeyboardKey) bool {
        _ = self;
        return rl.isKeyDown(key);
    }

    pub fn isKeyUp(self: Self, key: rl.KeyboardKey) bool {
        _ = self;
        return rl.isKeyUp(key);
    }

    pub fn isKeyPressed(self: Self, key: rl.KeyboardKey) bool {
        _ = self;
        return rl.isKeyPressed(key);
    }

    pub fn isKeyReleased(self: Self, key: rl.KeyboardKey) bool {
        _ = self;
        return rl.isKeyReleased(key);
    }

    // Mouse - Position
    pub fn getMousePosition(self: Self) rl.Vector2 {
        _ = self;
        return rl.getMousePosition();
    }

    pub fn getMouseX(self: Self) i32 {
        _ = self;
        return rl.getMouseX();
    }

    pub fn getMouseY(self: Self) i32 {
        _ = self;
        return rl.getMouseY();
    }

    // Mouse - Buttons
    pub fn isMouseButtonDown(self: Self, button: rl.MouseButton) bool {
        _ = self;
        return rl.isMouseButtonDown(button);
    }

    pub fn isMouseButtonUp(self: Self, button: rl.MouseButton) bool {
        _ = self;
        return rl.isMouseButtonUp(button);
    }

    pub fn isMouseButtonPressed(self: Self, button: rl.MouseButton) bool {
        _ = self;
        return rl.isMouseButtonPressed(button);
    }

    pub fn isMouseButtonReleased(self: Self, button: rl.MouseButton) bool {
        _ = self;
        return rl.isMouseButtonReleased(button);
    }

    // Mouse - Wheel
    pub fn getMouseWheelMove(self: Self) f32 {
        _ = self;
        return rl.getMouseWheelMove();
    }

    // Gamepad (future expansion)
    pub fn isGamepadAvailable(self: Self, gamepad: i32) bool {
        _ = self;
        return rl.isGamepadAvailable(gamepad);
    }

    pub fn getGamepadAxisMovement(self: Self, gamepad: i32, axis: rl.GamepadAxis) f32 {
        _ = self;
        return rl.getGamepadAxisMovement(gamepad, axis);
    }

    pub fn isGamepadButtonDown(self: Self, gamepad: i32, button: rl.GamepadButton) bool {
        _ = self;
        return rl.isGamepadButtonDown(gamepad, button);
    }

    pub fn isGamepadButtonPressed(self: Self, gamepad: i32, button: rl.GamepadButton) bool {
        _ = self;
        return rl.isGamepadButtonPressed(gamepad, button);
    }
};
