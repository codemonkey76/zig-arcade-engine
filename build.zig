const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const raylib_dep = b.dependency("raylib_zig", .{ .target = target });
    const raylib_mod = raylib_dep.module("raylib");

    const mod = b.addModule("engine", .{ .root_source_file = b.path("src/root.zig"), .target = target, .imports = &.{
        .{ .name = "raylib", .module = raylib_mod },
    } });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
