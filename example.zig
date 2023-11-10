const std = @import("std");
const vizops = @import("vizops");

pub fn main() !void {
    const v = vizops.vector.Float32Vector2.zero()
        .add(.{ @as(f32, 1.0), @as(f32, 0.5) })
        .sub(@as(f32, 2.0))
        .norm(@as(f32, 0.00000001));

    std.debug.print("{any}\n", .{v});

    var buf = std.io.fixedBufferStream(@embedFile("srgb.icc"));
    const icc = vizops.color.icc.read(std.heap.page_allocator, buf.reader()) catch |err| {
        std.debug.print("Buffer was at {}\n", .{buf.pos});
        return err;
    };
    defer icc.deinit();

    std.debug.print("{} {}\n", .{ icc, buf.pos });

    for (icc.tagdata.items) |item| std.debug.print("{}\n", .{item});
}
