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

    const Options = b.addOptions();
    Options.addOption([]const u8, "Version", "3.44.2");
    Options.addOption(bool, "AssertTypeStatementResult", b.option(bool, "assert_type", "Assert the type of the result of a statement") orelse (optimize == .Debug));

    const FLib = b.dependency("FLib", .{ .target = target, .optimize = optimize }).module("FLib");

    const ZSqlite = b.addModule("ZSqlite", .{
        .root_source_file = b.path("src/ZSqlite.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "FLib", .module = FLib },
        },
    });

    ZSqlite.addOptions("Config", Options);

    ZSqlite.linkLibrary(sqliteLib);
    ZSqlite.addIncludePath(b.path("include/"));

    const ZSqliteUnitTests = b.addTest(.{
        .root_source_file = b.path("src/Test.zig"),
        .target = target,
        .optimize = optimize,
    });

    ZSqliteUnitTests.root_module.addImport("ZSqlite", ZSqlite);
    ZSqliteUnitTests.root_module.addImport("FLib", FLib);

    const UnitTestRun = b.addRunArtifact(ZSqliteUnitTests);

    const TestStep = b.step("test", "Run unit tests");
    TestStep.dependOn(&UnitTestRun.step);
}
