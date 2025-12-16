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

/// Sprite with flip information
pub const FlippedSprite = struct {
    sprite: Sprite,
    flip: FlipMode,
};

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
        use_horizontal_symmetry: bool,
        use_vertical_symmetry: bool,

        const Self = @This();

        // Get sprite for specific angle (in degrees)
        // Returns sprite with appropriate flip flags
        pub fn getSpriteForAngle(self: Self, angle_degrees: f32) ?FlippedSprite {
            var normalized = @mod(angle_degrees, 360.0);
            var flip = FlipMode{};

            // Handle symmetry
            if (self.use_horizontal_symmetry) {
                if (normalized > 180.0) {
                    normalized = 360.0 - normalized;
                    flip.horizontal = true;
                }
            }

            if (self.use_vertical_symmetry) {
                if (normalized > 90.0 and normalized < 270.0) {
                    if (normalized <= 180.0) {
                        normalized = 180.0 - normalized;
                    } else {
                        normalized = normalized - 180.0;
                    }
                    flip.vertical = true;
                }
            }

            // Find closest frame
            var closest_idx: usize = 0;
            var min_diff: f32 = 360.0;

            for (self.frames, 0..) |frame, i| {
                const diff = @abs(angleDifference(normalized, frame.angle));
                if (diff < min_diff) {
                    min_diff = diff;
                    closest_idx = i;
                }
            }

            const frame = self.frames[closest_idx];
            if (self.layout.getSprite(frame.id)) |sprite| {
                return .{
                    .sprite = sprite,
                    .flip = flip,
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
