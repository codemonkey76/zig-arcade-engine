const std = @import("std");
const sprite_manager = @import("sprite_manager.zig");
const Texture = @import("texture.zig").Texture;
const Rect = @import("../math/rect.zig").Rect;

// Test sprite IDs matching your game's rotation setup
const TestSpriteId = enum {
    rotation_270,
    rotation_285,
    rotation_300,
    rotation_315,
    rotation_330,
    rotation_345,
    rotation_0,
};

// Helper to create a dummy texture (we won't actually use it)
fn createDummyTexture() Texture {
    return .{
        .handle = undefined, // Not used in tests
        .width = 16,
        .height = 16,
    };
}

// Helper to create a test sprite layout
fn createTestLayout(allocator: std.mem.Allocator) !sprite_manager.SpriteLayout(TestSpriteId) {
    _ = allocator;
    const texture = createDummyTexture();
    var builder = sprite_manager.SpriteLayoutBuilder(TestSpriteId).init(allocator, texture);
    
    try builder.addSprite(.rotation_270, 0, 0, 16, 16);
    try builder.addSprite(.rotation_285, 16, 0, 16, 16);
    try builder.addSprite(.rotation_300, 32, 0, 16, 16);
    try builder.addSprite(.rotation_315, 48, 0, 16, 16);
    try builder.addSprite(.rotation_330, 64, 0, 16, 16);
    try builder.addSprite(.rotation_345, 80, 0, 16, 16);
    try builder.addSprite(.rotation_0, 96, 0, 16, 16);
    
    return builder.build();
}

// Helper to create rotation frames
fn createTestFrames() []const sprite_manager.RotationFrame(TestSpriteId) {
    const frames = [_]sprite_manager.RotationFrame(TestSpriteId){
        .{ .id = .rotation_270, .angle = 270.0 },
        .{ .id = .rotation_285, .angle = 285.0 },
        .{ .id = .rotation_300, .angle = 300.0 },
        .{ .id = .rotation_315, .angle = 315.0 },
        .{ .id = .rotation_330, .angle = 330.0 },
        .{ .id = .rotation_345, .angle = 345.0 },
        .{ .id = .rotation_0, .angle = 0.0 },
    };
    return &frames;
}

test "getSpriteForAngle - 270-360 range (no flip expected)" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    // Test angles in the 270-360 range - should have NO flips
    const test_cases = [_]struct { angle: f32, expected_base: TestSpriteId }{
        .{ .angle = 270.0, .expected_base = .rotation_270 },
        .{ .angle = 275.0, .expected_base = .rotation_270 }, // Closer to 270
        .{ .angle = 280.0, .expected_base = .rotation_285 }, // Closer to 285
        .{ .angle = 285.0, .expected_base = .rotation_285 },
        .{ .angle = 292.5, .expected_base = .rotation_285 }, // Midpoint
        .{ .angle = 300.0, .expected_base = .rotation_300 },
        .{ .angle = 307.5, .expected_base = .rotation_300 },
        .{ .angle = 315.0, .expected_base = .rotation_315 },
        .{ .angle = 322.5, .expected_base = .rotation_315 },
        .{ .angle = 330.0, .expected_base = .rotation_330 },
        .{ .angle = 337.5, .expected_base = .rotation_330 },
        .{ .angle = 345.0, .expected_base = .rotation_345 },
        .{ .angle = 352.5, .expected_base = .rotation_345 },
        .{ .angle = 357.5, .expected_base = .rotation_0 },
        .{ .angle = 360.0, .expected_base = .rotation_0 },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("FAIL: angle {d} returned null\n", .{tc.angle});
            return error.NullResult;
        };
        
        if (result.flip.horizontal or result.flip.vertical) {
            std.debug.print("FAIL: angle {d} in 270-360 range has flip: H={} V={}\n", .{
                tc.angle,
                result.flip.horizontal,
                result.flip.vertical,
            });
            return error.UnexpectedFlip;
        }
        
        std.debug.print("PASS: angle {d:.1} -> sprite {s}, flip H={} V={}\n", .{
            tc.angle,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
        });
    }
}

test "getSpriteForAngle - 0-90 range (horizontal flip expected)" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    // Test angles in the 0-90 range - should have HORIZONTAL flip only
    const test_cases = [_]struct { angle: f32, desc: []const u8 }{
        .{ .angle = 0.0, .desc = "0 degrees" },
        .{ .angle = 7.5, .desc = "7.5 degrees (close to 0)" },
        .{ .angle = 15.0, .desc = "15 degrees" },
        .{ .angle = 30.0, .desc = "30 degrees" },
        .{ .angle = 45.0, .desc = "45 degrees" },
        .{ .angle = 60.0, .desc = "60 degrees" },
        .{ .angle = 75.0, .desc = "75 degrees" },
        .{ .angle = 90.0, .desc = "90 degrees" },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("FAIL: {s} returned null\n", .{tc.desc});
            return error.NullResult;
        };
        
        if (!result.flip.horizontal or result.flip.vertical) {
            std.debug.print("FAIL: {s} expected H flip only, got H={} V={}\n", .{
                tc.desc,
                result.flip.horizontal,
                result.flip.vertical,
            });
            return error.WrongFlipMode;
        }
        
        std.debug.print("PASS: {s} -> sprite {s}, flip H={} V={}\n", .{
            tc.desc,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
        });
    }
}

test "getSpriteForAngle - 90-180 range (both flips expected)" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    // Test angles in the 90-180 range - should have BOTH flips
    const test_cases = [_]struct { angle: f32, desc: []const u8 }{
        .{ .angle = 90.0, .desc = "90 degrees" },
        .{ .angle = 105.0, .desc = "105 degrees" },
        .{ .angle = 120.0, .desc = "120 degrees" },
        .{ .angle = 135.0, .desc = "135 degrees" },
        .{ .angle = 150.0, .desc = "150 degrees" },
        .{ .angle = 165.0, .desc = "165 degrees" },
        .{ .angle = 180.0, .desc = "180 degrees" },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("FAIL: {s} returned null\n", .{tc.desc});
            return error.NullResult;
        };
        
        if (!result.flip.horizontal or !result.flip.vertical) {
            std.debug.print("FAIL: {s} expected both flips, got H={} V={}\n", .{
                tc.desc,
                result.flip.horizontal,
                result.flip.vertical,
            });
            return error.WrongFlipMode;
        }
        
        std.debug.print("PASS: {s} -> sprite {s}, flip H={} V={}\n", .{
            tc.desc,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
        });
    }
}

test "getSpriteForAngle - 180-270 range (vertical flip expected)" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    // Test angles in the 180-270 range - should have VERTICAL flip only
    const test_cases = [_]struct { angle: f32, desc: []const u8 }{
        .{ .angle = 180.0, .desc = "180 degrees" },
        .{ .angle = 195.0, .desc = "195 degrees" },
        .{ .angle = 210.0, .desc = "210 degrees" },
        .{ .angle = 225.0, .desc = "225 degrees" },
        .{ .angle = 240.0, .desc = "240 degrees" },
        .{ .angle = 255.0, .desc = "255 degrees" },
        .{ .angle = 270.0, .desc = "270 degrees" },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("FAIL: {s} returned null\n", .{tc.desc});
            return error.NullResult;
        };
        
        if (result.flip.horizontal or !result.flip.vertical) {
            std.debug.print("FAIL: {s} expected V flip only, got H={} V={}\n", .{
                tc.desc,
                result.flip.horizontal,
                result.flip.vertical,
            });
            return error.WrongFlipMode;
        }
        
        std.debug.print("PASS: {s} -> sprite {s}, flip H={} V={}\n", .{
            tc.desc,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
        });
    }
}

test "getSpriteForAngle - comprehensive quadrant test" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    std.debug.print("\n=== Comprehensive Quadrant Test ===\n", .{});
    
    // Test every 15 degrees
    var angle: f32 = 0.0;
    while (angle < 360.0) : (angle += 15.0) {
        const result = rotation_set.getSpriteForAngle(angle) orelse {
            std.debug.print("FAIL: angle {d} returned null\n", .{angle});
            return error.NullResult;
        };
        
        // Determine expected flip based on quadrant
        const expected_h = angle >= 0.0 and angle < 180.0;
        const expected_v = angle >= 90.0 and angle < 270.0;
        
        const status = if (result.flip.horizontal == expected_h and result.flip.vertical == expected_v)
            "PASS"
        else
            "FAIL";
        
        std.debug.print("{s}: angle {d:>5.1} -> sprite {s:>16}, flip H={} V={} (expected H={} V={})\n", .{
            status,
            angle,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
            expected_h,
            expected_v,
        });
        
        if (result.flip.horizontal != expected_h or result.flip.vertical != expected_v) {
            return error.WrongFlipMode;
        }
    }
}

test "getSpriteForAngle - edge cases at quadrant boundaries" {
    const allocator = std.testing.allocator;
    const layout = try createTestLayout(allocator);
    const frames = createTestFrames();
    
    const rotation_set = sprite_manager.RotationSet(TestSpriteId){
        .layout = layout,
        .frames = frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    std.debug.print("\n=== Quadrant Boundary Tests ===\n", .{});
    
    const test_cases = [_]struct {
        angle: f32,
        expected_h: bool,
        expected_v: bool,
        desc: []const u8,
    }{
        .{ .angle = 0.0, .expected_h = true, .expected_v = false, .desc = "0° (boundary 270-0)" },
        .{ .angle = 90.0, .expected_h = true, .expected_v = true, .desc = "90° (boundary 0-180)" },
        .{ .angle = 180.0, .expected_h = false, .expected_v = true, .desc = "180° (boundary 90-270)" },
        .{ .angle = 270.0, .expected_h = false, .expected_v = false, .desc = "270° (boundary 180-360)" },
        .{ .angle = 359.9, .expected_h = false, .expected_v = false, .desc = "359.9° (almost 0)" },
        .{ .angle = 0.1, .expected_h = true, .expected_v = false, .desc = "0.1° (just past 0)" },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("FAIL: {s} returned null\n", .{tc.desc});
            return error.NullResult;
        };
        
        if (result.flip.horizontal != tc.expected_h or result.flip.vertical != tc.expected_v) {
            std.debug.print("FAIL: {s} got H={} V={}, expected H={} V={}\n", .{
                tc.desc,
                result.flip.horizontal,
                result.flip.vertical,
                tc.expected_h,
                tc.expected_v,
            });
            return error.WrongFlipMode;
        }
        
        std.debug.print("PASS: {s} -> H={} V={}\n", .{
            tc.desc,
            result.flip.horizontal,
            result.flip.vertical,
        });
    }
}
