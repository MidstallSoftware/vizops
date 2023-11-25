const std = @import("std");
const vizops = @import("vizops");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

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
    std.debug.print("{} {} {} {} {}\n", .{ c, c.convert(.linearRGB).linearRGB, c.convert(.hsv).hsv, c.convert(.hsl).hsl, c.convert(.cmyk).cmyk });

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

    inline for (@typeInfo(vizops.color.fourcc.formats).Struct.decls) |d| {
        const f = @field(vizops.color.fourcc.formats, d.name);
        std.debug.print("\t{s} - {!any} - 0x{x}", .{ d.name, vizops.color.fourcc.Value.decode(f), f });

        if (vizops.color.fourcc.Value.decode(f) catch null) |a| {
            std.debug.print(" - {} {!any}\n", .{ a.width(), a.forAny() });
        } else {
            std.debug.print("\n", .{});
        }
    }

    const argb8888 = try vizops.color.fourcc.Value.decode(vizops.color.fourcc.formats.argb8888);
    const colorBuff = try c.allocWrite(alloc, argb8888);
    defer alloc.free(colorBuff);
    std.debug.print("Color as argb8888: {any}\n", .{colorBuff});

    //const icc = vizops.color.icc.read(std.heap.page_allocator, buf.reader()) catch |err| {
    //    std.debug.print("Buffer was at {}\n", .{buf.pos});
    //    return err;
    //};
    //defer icc.deinit();

    //std.debug.print("{} {}\n", .{ icc, buf.pos });

    //for (icc.tagdata.items) |item| std.debug.print("{}\n", .{item});
}
