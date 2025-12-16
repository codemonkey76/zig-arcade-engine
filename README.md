# Zig Arcade Engine

A lightweight 2D game engine for arcade-style games, built with Zig and raylib.

## Features

- **Virtual Resolution System** - Fixed game resolution with automatic scaling
- **Pixel-Perfect Rendering** - Optional SSAA (Super-Sample Anti-Aliasing)
- **Viewport Management** - Automatic letterboxing/pillarboxing while maintaining aspect ratio
- **Sprite System**
  - Enum-based sprite IDs for type safety
  - Animation support with looping/one-shot modes
  - Rotation sets with automatic symmetry (reduce sprite sheet size by 50%+)
  - Flexible sprite sheet layouts (grid or manual positioning)
- **Asset Management** - Texture loading and caching
- **Input Handling** - Keyboard and mouse input (with more planned)
- **DPI Independent** - Render to fixed resolution, scale to any window size

## Requirements

- Zig 0.15.2 or later
- No external dependencies (raylib is bundled via raylib-zig)

## Installation

### As a Zig Package

Add to your `build.zig.zon`:
```zig
.dependencies = .{
    .engine = .{
        .url = "git+https://github.com/codemonkey76/zig-arcade-engine#v0.1.0",
        .hash = "12200000000000000000000000000000000000000000000000000000000000000000",
        // ^ Zig will tell you the correct hash when you run `zig build`
    },
},
```

Then in your `build.zig`:
```zig
const engine_dep = b.dependency("engine", .{
    .target = target,
    .optimize = optimize,
});
const engine_mod = engine_dep.module("engine");

const exe = b.addExecutable(.{
    .name = "my-game",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("engine", engine_mod);
```

## Quick Start

### Basic Game Setup
```zig
const std = @import("std");
const engine = @import("engine");

const GameState = struct {
    // Your game state here
};

const Game = struct {
    allocator: std.mem.Allocator,
    state: GameState,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        return .{
            .allocator = allocator,
            .state = .{},
        };
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn run(self: *@This()) !void {
        try engine.run(self.allocator, self, .{
            .init = onInit,
            .update = onUpdate,
            .draw = onDraw,
            .shutdown = onShutdown,
        }, .{
            .title = "My Game",
            .width = 1280,
            .height = 720,
            .virtual_width = 224,
            .virtual_height = 288,
            .target_fps = 60,
        });
    }

    fn onInit(ptr: *anyopaque, ctx: *engine.Context) !void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = ctx;
        // Initialize your game
    }

    fn onUpdate(ptr: *anyopaque, ctx: *engine.Context, dt: f32) !void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = ctx;
        _ = dt;
        // Update game logic
    }

    fn onDraw(ptr: *anyopaque, ctx: *engine.Context) !void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = ctx;
        // Draw your game
    }

    fn onShutdown(ptr: *anyopaque, ctx: *engine.Context) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        _ = self;
        _ = ctx;
        // Cleanup
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game = try Game.init(allocator);
    defer game.deinit();

    try game.run();
}
```

### Sprite System Example
```zig
// Define your sprite IDs
const SpriteId = enum {
    player_idle,
    player_walk_1,
    player_walk_2,
    enemy_1,
    bullet,
};

// Load and setup sprites
pub fn loadSprites(allocator: std.mem.Allocator, ctx: *engine.Context) !void {
    const texture = try engine.Texture.loadFromFile("assets/sprites.png");
    
    var builder = engine.SpriteLayoutBuilder(SpriteId).init(allocator, texture);
    try builder.addSprite(.player_idle, 0, 0, 32, 32);
    try builder.addSprite(.player_walk_1, 32, 0, 32, 32);
    try builder.addSprite(.player_walk_2, 64, 0, 32, 32);
    try builder.addSprite(.enemy_1, 0, 32, 32, 32);
    try builder.addSprite(.bullet, 96, 0, 8, 16);
    
    const layout = builder.build();
    
    // Create an animation
    const walk_anim = engine.AnimationDef(SpriteId){
        .layout = layout,
        .frames = &[_]SpriteId{ .player_walk_1, .player_walk_2 },
        .frame_duration = 0.1,
        .looping = true,
    };
    
    // Use the animation
    var anim_state = engine.AnimationState.init();
    
    // In your update loop:
    if (anim_state.update(dt, walk_anim)) |sprite| {
        // Draw the sprite
        ctx.gfx.drawSprite(sprite, position);
    }
}
```

### Rotation System with Symmetry
```zig
const SpriteId = enum {
    ship_270, ship_285, ship_300, ship_315, ship_330, ship_345,
};

// Setup rotation set
const frames = try allocator.alloc(engine.RotationFrame(SpriteId), 6);
frames[0] = .{ .id = .ship_270, .angle = 270.0 };
frames[1] = .{ .id = .ship_285, .angle = 285.0 };
frames[2] = .{ .id = .ship_300, .angle = 300.0 };
frames[3] = .{ .id = .ship_315, .angle = 315.0 };
frames[4] = .{ .id = .ship_330, .angle = 330.0 };
frames[5] = .{ .id = .ship_345, .angle = 345.0 };

const rotation_set = engine.RotationSet(SpriteId){
    .layout = layout,
    .frames = frames,
    .use_horizontal_symmetry = true,  // Auto-generate 0-90° from 270-360°
    .use_vertical_symmetry = false,
};

// Get sprite for any angle
if (rotation_set.getSpriteForAngle(player_angle)) |flipped| {
    ctx.gfx.drawFlippedSprite(flipped, position);
}
```

## Configuration Options
```zig
engine.Config{
    .title = "My Game",           // Window title
    .width = 1280,                // Window width
    .height = 720,                // Window height
    .virtual_width = 224,         // Game resolution width
    .virtual_height = 288,        // Game resolution height
    .ssaa_scale = 2,              // Super-sampling (2 = 2x resolution)
    .target_fps = 60,             // Target frame rate
    .resizable = true,            // Allow window resizing
    .fullscreen = false,          // Start in fullscreen
    .asset_root = "assets",       // Asset directory path
}
```

## Architecture
```
┌─────────────────────────────────────┐
│          Your Game Code             │
├─────────────────────────────────────┤
│         Engine Context              │
│  ┌──────────┬──────────┬─────────┐ │
│  │ Viewport │  Assets  │  Input  │ │
│  ├──────────┼──────────┼─────────┤ │
│  │  Sprites │    Gfx   │ Window  │ │
│  └──────────┴──────────┴─────────┘ │
├─────────────────────────────────────┤
│           raylib-zig                │
└─────────────────────────────────────┘
```

## Examples

See the [examples](examples/) directory for complete game examples:

- `examples/basic/` - Minimal game setup
- `examples/sprites/` - Sprite and animation system
- `examples/rotations/` - Rotation sets with symmetry

## Roadmap

- [ ] Audio system
- [ ] Tilemap support
- [ ] Particle system
- [ ] Collision detection helpers
- [ ] Gamepad input
- [ ] Scene management
- [ ] Debug overlay/console

## Contributing

Contributions are welcome! Please open an issue or PR.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [Zig](https://ziglang.org/)
- Uses [raylib](https://www.raylib.com/) via [raylib-zig](https://github.com/Not-Nik/raylib-zig)

## Games Made With This Engine

- [Zalaga](https://github.com/codemonkey76/zalaga) - Galaga clone
- [PathSketcher](https://github.com/codemonkey76/path-sketcher) - Path sketch tool.
*Add your game here!*
