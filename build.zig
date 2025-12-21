const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const raylib_dep = b.dependency("raylib_zig", .{ .target = target });
    const raylib_mod = raylib_dep.module("raylib");

    const lib_dep = b.dependency("arcade_lib", .{ .target = target });
    const lib_mod = lib_dep.module("arcade_lib");

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/mod.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "raylib", .module = raylib_mod },
            .{ .name = "arcade_lib", .module = lib_mod },
        },
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
