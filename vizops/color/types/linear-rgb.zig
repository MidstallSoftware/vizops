const std = @import("std");

pub fn linearRGB(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Type = @Vector(4, T);

        value: Type = @splat(0),

        pub usingnamespace @import("base.zig").Color(linearRGB, Self, T);
    };
}
