const std = @import("std");

pub fn Cmyk(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Type = @Vector(5, T);

        value: Type = @splat(0),

        pub usingnamespace @import("base.zig").Color(Cmyk, Self, T);
    };
}
