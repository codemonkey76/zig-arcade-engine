const rl = @import("raylib");
const Config = @import("config.zig").Config;

pub const Window = struct {
    width: u32,
    height: u32,
    should_close: bool,

    const Self = @This();

    pub fn init(cfg: Config) Self {
        rl.initWindow(
            @intCast(cfg.width),
            @intCast(cfg.height),
            cfg.title,
        );

        if (cfg.resizable) rl.setWindowState(rl.ConfigFlags{ .window_resizable = true });
        if (cfg.fullscreen) rl.toggleBorderlessWindowed();
        rl.setTargetFPS(@intCast(cfg.target_fps));

        return .{
            .width = cfg.width,
            .height = cfg.height,
            .should_close = false,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
        rl.closeWindow();
    }

    pub fn update(self: *Self) void {
        if (rl.windowShouldClose()) self.should_close = true;
    }
};
