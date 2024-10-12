const std = @import("std");

// for target
// const sqliteDep = b.dependency("sqlite", .{ .target = target, .optimize = optimize });

// current sqlite version : 3.44.2

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sqliteLib = b.addStaticLibrary(.{
        .name = "sqlite",
        .target = target,
        .optimize = optimize,
    });

    sqliteLib.addIncludePath(b.path("include/"));

    sqliteLib.addCSourceFile(.{
        .file = b.path("csrc/sqlite3.c"),
        .flags = &[_][]const u8{"-std=c99"},
    });

    sqliteLib.linkLibC();

    const testExe = b.addExecutable(.{
        .name = "sqliteTest",
        .root_source_file = b.path("test.zig"),
        .target = target,
        .optimize = optimize,
    });

    testExe.linkLibrary(sqliteLib);
    testExe.addIncludePath(b.path("include/"));

    b.installArtifact(testExe);
}
