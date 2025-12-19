const std = @import("std");
const ContextFn = @import("context.zig").Context;
const Config = @import("config.zig").Config;

pub fn GameVTable(comptime CtxType: type) type {
    return struct {
        init: *const fn (*anyopaque, *CtxType) anyerror!void,
        update: *const fn (*anyopaque, *CtxType, dt: f32) anyerror!void,
        draw: *const fn (*anyopaque, *CtxType) anyerror!void,
        shutdown: *const fn (*anyopaque, *CtxType) void,
    };
}

pub fn run(
    comptime SoundId: type,
    allocator: std.mem.Allocator,
    game_ptr: *anyopaque,
    game: GameVTable(ContextFn(SoundId)),
    cfg: Config,
) !void {
    const Context = ContextFn(SoundId);
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
