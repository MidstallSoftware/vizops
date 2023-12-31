const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_docs = b.option(bool, "no-docs", "skip installing documentation") orelse false;

    const metaplus = b.dependency("metaplus", .{
        .target = target,
        .optimize = optimize,
    });

    const vizops = b.addModule("vizops", .{
        .root_source_file = .{ .path = b.pathFromRoot("vizops.zig") },
        .imports = &.{.{
            .name = "meta+",
            .module = metaplus.module("meta+"),
        }},
    });

    const step_test = b.step("test", "Run all unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = .{
            .path = b.pathFromRoot("vizops.zig"),
        },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.root_module.addImport("meta+", metaplus.module("meta+"));

    const run_unit_tests = b.addRunArtifact(unit_tests);
    step_test.dependOn(&run_unit_tests.step);

    const exe_example = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{
            .path = b.pathFromRoot("example.zig"),
        },
        .target = target,
        .optimize = optimize,
    });

    exe_example.root_module.addImport("vizops", vizops);
    b.installArtifact(exe_example);

    if (!no_docs) {
        const docs = b.addInstallDirectory(.{
            .source_dir = unit_tests.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        });

        b.getInstallStep().dependOn(&docs.step);
    }
}
