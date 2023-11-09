const std = @import("std");
const vizops = @import("vizops");

pub fn main() !void {
    const v = vizops.vector.Float32Vector2.zero()
        .add(.{ @as(f32, 1.0), @as(f32, 0.5) })
        .sub(@as(f32, 2.0))
        .norm(@as(f32, 0.00000001));

    std.debug.print("{any}\n", .{v});

    const c = vizops.color.types.xyY(f32){
        .value = @splat(5.0),
    };

    std.debug.print("{} {} {}\n", .{ c.convert(.lab), c.convert(.xyz), c.convert(.lch) });
}
