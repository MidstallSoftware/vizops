const std = @import("std");
const vizops = @import("vizops");

pub fn main() void {
    const vec2f = vizops.vector.Float32Vector2.zero()
        .add(vizops.vector.Float32Vector2.init(.{ 1.0, 0.5 }))
        .sub(@as(f32, 2.0));

    std.debug.print("{any}\n", .{vec2f});
}
