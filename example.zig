const std = @import("std");
const vizops = @import("vizops");

pub fn main() void {
    const v = vizops.vector.Float32Vector2.zero()
        .add([_]f32{ 1.0, 0.5 })
        .sub(@as(f32, 2.0))
        .norm(@as(f32, 0.00000001));

    std.debug.print("{any}\n", .{v});
}
