const std = @import("std");
const Context = @import("context.zig").Context;
const Config = @import("config.zig").Config;

pub const GameVTable = struct {
    init: *const fn (*anyopaque, *Context) anyerror!void,
    update: *const fn (*anyopaque, *Context, dt: f32) anyerror!void,
    draw: *const fn (*anyopaque, *Context) anyerror!void,
    shutdown: *const fn (*anyopaque, *Context) void,
};

pub fn run(
    allocator: std.mem.Allocator,
    game_ptr: *anyopaque,
    game: GameVTable,
    cfg: Config,
) !void {
    var ctx = try Context.init(allocator, cfg);
    defer ctx.deinit();

    ctx.fixPointers();

    try game.init(game_ptr, &ctx);
    defer game.shutdown(game_ptr, &ctx);

    while (!ctx.shouldQuit()) {
        const dt = ctx.tick();
        try game.update(game_ptr, &ctx, dt);

        ctx.beginFrame();
        try game.draw(game_ptr, &ctx);
        ctx.endFrame();
    }
}
