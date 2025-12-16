const std = @import("std");
const rl = @import("raylib");

const Config = @import("config.zig").Config;
const Input = @import("input.zig").Input;
const AssetManager = @import("assets.zig").AssetManager;
const Window = @import("window.zig").Window;
const Viewport = @import("viewport.zig").Viewport;
const Renderer = @import("renderer.zig").Renderer;

pub const Context = struct {
    allocator: std.mem.Allocator,

    input: Input,
    renderer: Renderer,
    assets: AssetManager,
    window: Window,
    viewport: Viewport,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, cfg: Config) !Self {
        var self: Self = .{
            .allocator = allocator,
            .input = Input.init(),
            .renderer = undefined,
            .assets = try AssetManager.init(allocator, cfg.asset_root),
            .window = Window.init(cfg),
            .viewport = try Viewport.init(
                cfg.virtual_width,
                cfg.virtual_height,
                cfg.ssaa_scale,
            ),
        };

        self.viewport.updateDestRect(cfg.width, cfg.height);
        self.renderer = Renderer.init(&self.viewport);

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.viewport.deinit();
        self.assets.deinit();
        self.window.deinit();
    }

    pub fn shouldQuit(self: *const Self) bool {
        return self.window.should_close;
    }

    pub fn tick(self: *Self) f32 {
        self.window.update();

        // Update viewport if window was resized
        const current_width = @as(u32, @intCast(rl.getScreenWidth()));
        const current_height = @as(u32, @intCast(rl.getScreenHeight()));
        if (current_width != self.window.width or current_height != self.window.height) {
            self.window.width = current_width;
            self.window.height = current_height;
            self.viewport.updateDestRect(current_width, current_height);
        }

        return rl.getFrameTime();
    }

    pub fn beginFrame(self: *Self) void {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        self.viewport.beginRender();
    }

    pub fn endFrame(self: *Self) void {
        self.viewport.endRender();
        self.viewport.draw();
        rl.endDrawing();
    }
};
