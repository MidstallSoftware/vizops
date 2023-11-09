const std = @import("std");
const vizops = @import("vizops");

pub fn main() !void {
    const v = vizops.vector.Float32Vector2.zero()
        .add(.{ @as(f32, 1.0), @as(f32, 0.5) })
        .sub(@as(f32, 2.0))
        .norm(@as(f32, 0.00000001));

    std.debug.print("{any}\nFourCC:\n", .{v});

    inline for (@typeInfo(vizops.fourcc.formats).Struct.decls) |d| {
        const f = @field(vizops.fourcc.formats, d.name);
        std.debug.print("\t{s} - {!any} - 0x{x}", .{ d.name, vizops.fourcc.Value.decode(f), f });

        if (vizops.fourcc.Value.decode(f) catch null) |a| {
            std.debug.print(" - {}\n", .{a.width()});
        } else {
            std.debug.print("\n", .{});
        }
    }
}
