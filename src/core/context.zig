const std = @import("std");
const rl = @import("raylib");

const Config = @import("config.zig").Config;
const Input = @import("../input/input.zig").Input;
const AssetManagerFn = @import("../assets/assets.zig").AssetManager;
const Window = @import("window.zig").Window;
const Viewport = @import("../graphics/viewport.zig").Viewport;
const Renderer = @import("../graphics/renderer.zig").Renderer;
const Logger = @import("logger.zig").Logger;

pub fn Context(
    comptime TextureAsset: type,
    comptime FontAsset: type,
    comptime PathAsset: type,
    comptime SoundAsset: type,
) type {
    const AssetManager = AssetManagerFn(
        TextureAsset,
        FontAsset,
        PathAsset,
        SoundAsset,
    );

    return struct {
        allocator: std.mem.Allocator,

        input: Input,
        renderer: Renderer,
        assets: AssetManager,
        window: Window,
        viewport: Viewport,
        logger: Logger,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, cfg: Config) !Self {
            rl.setTraceLogLevel(cfg.log_level);
            var logger = try Logger.init(allocator, "zalaga.log", cfg.log_level);
            errdefer logger.deinit();

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
                .logger = logger,
            };

            self.viewport.updateDestRect(cfg.width, cfg.height);
            self.renderer = Renderer.init(&self.viewport);

            return self;
        }

        pub fn deinit(self: *Self) void {
            self.viewport.deinit();
            self.assets.deinit();
            self.window.deinit();
            self.logger.deinit();
        }

        pub fn fixPointers(self: *Self) void {
            self.renderer.viewport = &self.viewport;
            self.renderer.text.viewport = &self.viewport;
        }

        pub fn setFont(self: *Self, font: ?rl.Font) void {
            self.renderer.text.setFont(font);
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
}
