const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const metaplus = b.dependency("metaplus", .{
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("meta+", .{
        .source_file = .{
            .path = metaplus.builder.pathFromRoot(metaplus.module("meta+").source_file.path),
        },
    });

    const vizops = b.addModule("vizops", .{
        .source_file = .{ .path = b.pathFromRoot("src/vizops.zig") },
        .dependencies = &.{.{
            .name = "meta+",
            .module = metaplus.module("meta+"),
        }},
    });

    const step_test = b.step("test", "Run all unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = .{
            .path = b.pathFromRoot("src/vizops.zig"),
        },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addModule("meta+", metaplus.module("meta+"));

    const run_unit_tests = b.addRunArtifact(unit_tests);
    step_test.dependOn(&run_unit_tests.step);

    const exe_example = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{
            .path = b.pathFromRoot("src/example.zig"),
        },
        .target = target,
        .optimize = optimize,
    });

    exe_example.addModule("vizops", vizops);
    b.installArtifact(exe_example);
}
