const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vizops = b.addModule("vizops", .{
        .source_file = .{ .path = b.pathFromRoot("src/vizops.zig") },
    });

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
