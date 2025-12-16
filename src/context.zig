const std = @import("std");
const rl = @import("raylib");

const Config = @import("config.zig").Config;
const Input = @import("input.zig").Input;
const AssetManager = @import("assets.zig").AssetManager;
const Window = @import("window.zig").Window;
const Viewport = @import("viewport.zig").Viewport;
const Gfx = @import("gfx.zig").Gfx;

pub const Context = struct {
    allocator: std.mem.Allocator,

    input: Input,
    gfx: Gfx,
    assets: AssetManager,
    window: Window,
    viewport: Viewport,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, cfg: Config) !Self {
        const window = Window.init(cfg);

        var viewport = try Viewport.init(
            cfg.virtual_width,
            cfg.virtual_height,
            cfg.ssaa_scale,
        );
        viewport.updateDestRect(cfg.width, cfg.height);
        return .{
            .allocator = allocator,
            .input = Input.init(),
            .gfx = Gfx{},
            .assets = try AssetManager.init(allocator, cfg.asset_root),
            .window = window,
            .viewport = viewport,
        };
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
