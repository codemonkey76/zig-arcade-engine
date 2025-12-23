const std = @import("std");
const rl = @import("raylib");

const Texture = @import("texture.zig").Texture;
const Rect = @import("../math/rect.zig").Rect;

/// Flip mode for sprite rendering
pub const FlipMode = packed struct {
    horizontal: bool = false,
    vertical: bool = false,
};

/// Sprite definition
pub const Sprite = struct {
    texture: Texture,
    region: Rect,

    const Self = @This();

    pub fn getWidth(self: Self) f32 {
        return self.region.w;
    }

    pub fn getHeight(self: Self) f32 {
        return self.region.h;
    }

    pub fn getSourceRect(self: Self) rl.Rectangle {
        return .{
            .x = self.region.x,
            .y = self.region.y,
            .width = self.region.w,
            .height = self.region.h,
        };
    }
};

/// Sprite with flip information (generic over SpriteId type)
pub fn FlippedSprite(comptime SpriteId: type) type {
    return struct {
        sprite: Sprite,
        flip: FlipMode,
        id: SpriteId,
    };
}

/// Generic sprite layout information using an enum for Sprite IDs
pub fn SpriteLayout(comptime SpriteId: type) type {
    return struct {
        texture: Texture,
        sprites: std.EnumMap(SpriteId, Sprite),

        const Self = @This();

        /// Get sprite by ID
        pub fn getSprite(self: Self, id: SpriteId) ?Sprite {
            return self.sprites.get(id);
        }

        /// Check if sprite exists
        pub fn hasSprite(self: Self, id: SpriteId) bool {
            return self.sprites.contains(id);
        }
    };
}

/// Builder for creating sprite layouts
pub fn SpriteLayoutBuilder(comptime SpriteId: type) type {
    return struct {
        allocator: std.mem.Allocator,
        texture: Texture,
        sprites: std.EnumMap(SpriteId, Sprite),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, texture: Texture) Self {
            return .{
                .allocator = allocator,
                .texture = texture,
                .sprites = std.EnumMap(SpriteId, Sprite){},
            };
        }

        /// Add a sprite with explicit coordinates
        pub fn addSprite(self: *Self, id: SpriteId, x: f32, y: f32, w: f32, h: f32) !void {
            self.sprites.put(id, .{
                .texture = self.texture,
                .region = .{ .x = x, .y = y, .w = w, .h = h },
            });
        }

        /// Add a sprite with a rect
        pub fn addSpriteRect(self: *Self, id: SpriteId, region: Rect) !void {
            self.sprites.put(id, .{
                .texture = self.texture,
                .region = region,
            });
        }

        /// Build the final layout
        pub fn build(self: *Self) SpriteLayout(SpriteId) {
            return .{
                .texture = self.texture,
                .sprites = self.sprites,
            };
        }
    };
}

/// Frame definition with rotation angle (generic over Sprite ID type)
pub fn RotationFrame(comptime SpriteId: type) type {
    return struct {
        id: SpriteId, // Sprite ID instead of index
        angle: f32, // angle this frame represents (in degrees)
    };
}

/// Rotation set for directional sprites with symmetry support
pub fn RotationSet(comptime SpriteId: type) type {
    return struct {
        layout: SpriteLayout(SpriteId),
        frames: []const RotationFrame(SpriteId),
        allow_horizontal_flip: bool,
        allow_vertical_flip: bool,

        const Self = @This();

        pub fn getSpriteForAngle(self: Self, angle_degrees: f32) ?FlippedSprite(SpriteId) {
            const normalized = @mod(angle_degrees, 360.0);

            var best_flip = FlipMode{};
            var min_diff: f32 = 360.0;
            var closest_idx: usize = 0;

            // Check all frames with all possible flip combinations
            for (self.frames, 0..) |frame, i| {
                // Check: no flip
                {
                    const diff = @abs(angleDifference(normalized, frame.angle));
                    if (diff < min_diff) {
                        min_diff = diff;
                        closest_idx = i;
                        best_flip = FlipMode{};
                    }
                }

                // Check: horizontal flip (mirrors across vertical/Y axis)
                // Sprite at angle X represents 360-X when horizontally flipped
                if (self.allow_horizontal_flip) {
                    const flipped_angle = @mod(360.0 - frame.angle, 360.0);
                    const diff = @abs(angleDifference(normalized, flipped_angle));
                    if (diff < min_diff) {
                        min_diff = diff;
                        closest_idx = i;
                        best_flip = FlipMode{ .horizontal = true };
                    }
                }

                // Check: vertical flip (mirrors across horizontal/X axis)
                // Sprite at angle X represents 180-X when vertically flipped
                if (self.allow_vertical_flip) {
                    const flipped_angle = @mod(180.0 - frame.angle, 360.0);
                    const diff = @abs(angleDifference(normalized, flipped_angle));
                    if (diff < min_diff) {
                        min_diff = diff;
                        closest_idx = i;
                        best_flip = FlipMode{ .vertical = true };
                    }
                }

                // Check: both flips (H then V, or V then H - commutative)
                // Sprite at angle X represents 180-(360-X) = X-180 = (180+X) mod 360
                if (self.allow_horizontal_flip and self.allow_vertical_flip) {
                    const flipped_angle = @mod(180.0 + frame.angle, 360.0);
                    const diff = @abs(angleDifference(normalized, flipped_angle));
                    if (diff < min_diff) {
                        min_diff = diff;
                        closest_idx = i;
                        best_flip = FlipMode{ .horizontal = true, .vertical = true };
                    }
                }
            }

            const frame = self.frames[closest_idx];
            if (self.layout.getSprite(frame.id)) |sprite| {
                return .{
                    .sprite = sprite,
                    .flip = best_flip,
                    .id = frame.id,
                };
            }
            return null;
        }

        /// Calculate shortest angular difference between two angles
        fn angleDifference(a: f32, b: f32) f32 {
            var diff = @mod(a - b, 360.0);
            if (diff > 180.0) {
                diff -= 360.0;
            } else if (diff < -180.0) {
                diff += 360.0;
            }
            return diff;
        }
    };
}

/// Animation sequence definition
pub fn AnimationDef(comptime SpriteId: type) type {
    return struct {
        layout: SpriteLayout(SpriteId),
        frames: []const SpriteId, // List of sprite IDS in order
        frame_duration: f32,
        looping: bool,

        const Self = @This();

        /// Get sprite for specific frame index
        pub fn getFrame(self: Self, frame_index: usize) ?Sprite {
            if (frame_index >= self.frames.len) return null;
            return self.layout.getSprite(self.frames[frame_index]);
        }
    };
}

// Runtime animation state
pub const AnimationState = struct {
    current_frame: usize,
    time_in_frame: f32,
    playing: bool,

    const Self = @This();

    pub fn init() AnimationState {
        return .{
            .current_frame = 0,
            .time_in_frame = 0.0,
            .playing = true,
        };
    }

    /// Update animation and return current sprite (generic over animation type)
    pub fn update(self: *Self, dt: f32, anim: anytype) ?Sprite {
        if (!self.playing) {
            return anim.getFrame(self.current_frame);
        }

        self.time_in_frame += dt;

        while (self.time_in_frame >= anim.frame_duration) {
            self.time_in_frame -= anim.frame_duration;
            self.current_frame += 1;

            if (self.current_frame >= anim.frames.len) {
                if (anim.looping) {
                    self.current_frame = 0;
                } else {
                    self.current_frame = anim.frames.len - 1;
                    self.playing = false;
                }
            }
        }

        return anim.getFrame(self.current_frame);
    }

    pub fn reset(self: *Self) void {
        self.current_frame = 0;
        self.time_in_frame = 0.0;
        self.playing = true;
    }

    pub fn pause(self: *Self) void {
        self.playing = false;
    }

    pub fn play(self: *Self) void {
        self.playing = true;
    }

    pub fn isFinished(self: Self, anim: anytype) bool {
        return !anim.looping and self.current_frame >= anim.frames.len - 1;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "RotationSet - getSpriteForAngle with symmetry" {
    const TestSpriteId = enum {
        rotation_270,
        rotation_285,
        rotation_300,
        rotation_315,
        rotation_330,
        rotation_345,
        rotation_0,
    };
    
    // Create a dummy texture
    const texture = Texture{
        .handle = undefined,
    };
    
    // Create sprite layout
    var builder = SpriteLayoutBuilder(TestSpriteId).init(std.testing.allocator, texture);
    try builder.addSprite(.rotation_270, 0, 0, 16, 16);
    try builder.addSprite(.rotation_285, 16, 0, 16, 16);
    try builder.addSprite(.rotation_300, 32, 0, 16, 16);
    try builder.addSprite(.rotation_315, 48, 0, 16, 16);
    try builder.addSprite(.rotation_330, 64, 0, 16, 16);
    try builder.addSprite(.rotation_345, 80, 0, 16, 16);
    try builder.addSprite(.rotation_0, 96, 0, 16, 16);
    const layout = builder.build();
    
    // Create rotation frames
    const frames = [_]RotationFrame(TestSpriteId){
        .{ .id = .rotation_270, .angle = 270.0 },
        .{ .id = .rotation_285, .angle = 285.0 },
        .{ .id = .rotation_300, .angle = 300.0 },
        .{ .id = .rotation_315, .angle = 315.0 },
        .{ .id = .rotation_330, .angle = 330.0 },
        .{ .id = .rotation_345, .angle = 345.0 },
        .{ .id = .rotation_0, .angle = 0.0 },
    };
    
    const rotation_set = RotationSet(TestSpriteId){
        .layout = layout,
        .frames = &frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    std.debug.print("\n=== Testing Rotation Set Behavior ===\n", .{});
    
    // Test every 15 degrees to get comprehensive coverage
    var angle: f32 = 0.0;
    var failures: u32 = 0;
    while (angle < 360.0) : (angle += 15.0) {
        const result = rotation_set.getSpriteForAngle(angle) orelse {
            std.debug.print("ERROR: angle {d} returned null\n", .{angle});
            failures += 1;
            continue;
        };
        
        // Expected flip based on requirements:
        // Sprites provided: 270, 285, 300, 315, 330, 345, 0 (West through North)
        // The algorithm picks the closest match, so:
        // - Near 0° (e.g., 355-5): uses rotation_0 with no flip
        // - 7.5-82.5 approx: uses sprites with H-flip
        // - 97.5-172.5 approx: uses sprites with H+V flip
        // - 187.5-262.5 approx: uses sprites with V-flip
        // - 277.5-352.5 approx: uses sprites with no flip
        
        var expected_h: bool = undefined;
        var expected_v: bool = undefined;
        var range_desc: []const u8 = undefined;
        
        // Determine expected based on which sprite will be closest
        // rotation_0 at 0° covers roughly 352.5-7.5 with no flip
        if ((angle >= 352.5 and angle < 360.0) or (angle >= 0.0 and angle <= 7.5)) {
            expected_h = false;
            expected_v = false;
            range_desc = "near 0°";
        } else if (angle > 7.5 and angle < 90.0) {
            // Will use sprites from 270-360 range with H-flip
            expected_h = true;
            expected_v = false;
            range_desc = "~8-90";
        } else if (angle == 90.0) {
            // Special boundary case - accept either H or H+V
            const has_h_only = result.flip.horizontal and !result.flip.vertical;
            const has_both = result.flip.horizontal and result.flip.vertical;
            if (has_h_only or has_both) {
                std.debug.print("✓ angle {d:>5.1}° (boundary 90) -> {s:>16} | flip H={} V={} (H or H+V valid)\n", .{
                    angle,
                    @tagName(result.id),
                    result.flip.horizontal,
                    result.flip.vertical,
                });
                continue;
            } else {
                std.debug.print("✗ angle {d:>5.1}° (boundary 90) -> {s:>16} | flip H={} V={} (expected H or H+V)\n", .{
                    angle,
                    @tagName(result.id),
                    result.flip.horizontal,
                    result.flip.vertical,
                });
                failures += 1;
                continue;
            }
        } else if (angle > 90.0 and angle < 180.0) {
            // Both flips
            expected_h = true;
            expected_v = true;
            range_desc = "90-180";
        } else if (angle >= 180.0 and angle < 270.0) {
            // V-flip only
            expected_h = false;
            expected_v = true;
            range_desc = "180-270";
        } else { // 270 <= angle < 352.5
            // No flip
            expected_h = false;
            expected_v = false;
            range_desc = "270-352.5";
        }
        
        const correct = result.flip.horizontal == expected_h and result.flip.vertical == expected_v;
        const status = if (correct) "✓" else "✗";
        
        std.debug.print("{s} angle {d:>5.1}° ({s:>12}) -> {s:>16} | flip H={} V={} | expected H={} V={}\n", .{
            status,
            angle,
            range_desc,
            @tagName(result.id),
            result.flip.horizontal,
            result.flip.vertical,
            expected_h,
            expected_v,
        });
        
        if (!correct) failures += 1;
    }
    
    if (failures > 0) {
        std.debug.print("\n{d} test cases FAILED\n", .{failures});
        return error.TestsFailed;
    }
    
    std.debug.print("\nAll test cases PASSED\n", .{});
}

test "RotationSet - quadrant boundaries" {
    const TestSpriteId = enum {
        rotation_270,
        rotation_285,
        rotation_300,
        rotation_315,
        rotation_330,
        rotation_345,
        rotation_0,
    };
    
    const texture = Texture{
        .handle = undefined,
    };
    
    var builder = SpriteLayoutBuilder(TestSpriteId).init(std.testing.allocator, texture);
    try builder.addSprite(.rotation_270, 0, 0, 16, 16);
    try builder.addSprite(.rotation_285, 16, 0, 16, 16);
    try builder.addSprite(.rotation_300, 32, 0, 16, 16);
    try builder.addSprite(.rotation_315, 48, 0, 16, 16);
    try builder.addSprite(.rotation_330, 64, 0, 16, 16);
    try builder.addSprite(.rotation_345, 80, 0, 16, 16);
    try builder.addSprite(.rotation_0, 96, 0, 16, 16);
    const layout = builder.build();
    
    const frames = [_]RotationFrame(TestSpriteId){
        .{ .id = .rotation_270, .angle = 270.0 },
        .{ .id = .rotation_285, .angle = 285.0 },
        .{ .id = .rotation_300, .angle = 300.0 },
        .{ .id = .rotation_315, .angle = 315.0 },
        .{ .id = .rotation_330, .angle = 330.0 },
        .{ .id = .rotation_345, .angle = 345.0 },
        .{ .id = .rotation_0, .angle = 0.0 },
    };
    
    const rotation_set = RotationSet(TestSpriteId){
        .layout = layout,
        .frames = &frames,
        .allow_horizontal_flip = true,
        .allow_vertical_flip = true,
    };
    
    std.debug.print("\n=== Testing Quadrant Boundaries ===\n", .{});
    
    const test_cases = [_]struct {
        angle: f32,
        expected_h: bool,
        expected_v: bool,
        allow_either: bool, // True if multiple flip combinations are valid
        desc: []const u8,
    }{
        .{ .angle = 0.0, .expected_h = false, .expected_v = false, .allow_either = false, .desc = "0° (North - symmetrical, no flip needed)" },
        .{ .angle = 90.0, .expected_h = true, .expected_v = true, .allow_either = true, .desc = "90° (East - boundary, H or H+V valid)" },
        .{ .angle = 180.0, .expected_h = false, .expected_v = true, .allow_either = false, .desc = "180° (South - boundary)" },
        .{ .angle = 270.0, .expected_h = false, .expected_v = false, .allow_either = false, .desc = "270° (West - start of base range)" },
        .{ .angle = 359.9, .expected_h = false, .expected_v = false, .allow_either = false, .desc = "359.9° (almost 0, no flip)" },
        .{ .angle = 10.0, .expected_h = true, .expected_v = false, .allow_either = false, .desc = "10° (away from 0, H flip)" },
    };
    
    for (test_cases) |tc| {
        const result = rotation_set.getSpriteForAngle(tc.angle) orelse {
            std.debug.print("ERROR: {s} returned null\n", .{tc.desc});
            return error.NullResult;
        };
        
        // For 90°, accept either H-only or H+V as both are mathematically valid
        const correct = if (tc.allow_either and tc.angle == 90.0)
            (result.flip.horizontal and !result.flip.vertical) or (result.flip.horizontal and result.flip.vertical)
        else
            result.flip.horizontal == tc.expected_h and result.flip.vertical == tc.expected_v;
            
        const status = if (correct) "✓" else "✗";
        
        std.debug.print("{s} {s:50} -> H={} V={} (expected H={} V={})\n", .{
            status,
            tc.desc,
            result.flip.horizontal,
            result.flip.vertical,
            tc.expected_h,
            tc.expected_v,
        });
        
        if (!correct) return error.WrongFlipMode;
    }
    
    std.debug.print("All boundary tests PASSED\n", .{});
}
