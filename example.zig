const std = @import("std");
const vizops = @import("vizops");

pub fn main() !void {
    const v = vizops.vector.Float32Vector2.zero()
        .add(.{ @as(f32, 1.0), @as(f32, 0.5) })
        .sub(@as(f32, 2.0))
        .norm(@as(f32, 0.00000001));

    std.debug.print("{any}\n", .{v});

    const c = vizops.color.types.sRGB(u8).init(.{ @as(u8, 0), @as(u8, 255), @as(u8, 0), @as(u8, 255) })
        .channel(.red)
        .set(25)
        .done()
        .channel(.alpha)
        .div(10)
        .done();
    std.debug.print("{any}\n", .{c});

    var buf = std.io.fixedBufferStream(@embedFile("srgb.icc"));
    const header = vizops.color.icc.Header.read(buf.reader()) catch |err| {
        std.debug.print("Buffer was at {}\n", .{buf.pos});
        return err;
    };
    std.debug.print("{}\n", .{header});

    const tags = vizops.color.icc.Tags.read(std.heap.page_allocator, buf.reader()) catch |err| {
        std.debug.print("Buffer was at {}\n", .{buf.pos});
        return err;
    };
    defer tags.deinit();
    std.debug.print("{}\n", .{tags});

    //const icc = vizops.color.icc.read(std.heap.page_allocator, buf.reader()) catch |err| {
    //    std.debug.print("Buffer was at {}\n", .{buf.pos});
    //    return err;
    //};
    //defer icc.deinit();

    //std.debug.print("{} {}\n", .{ icc, buf.pos });

    //for (icc.tagdata.items) |item| std.debug.print("{}\n", .{item});
}
