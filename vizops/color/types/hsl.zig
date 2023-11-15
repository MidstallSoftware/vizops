const std = @import("std");

pub fn Hsl(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Type = @Vector(4, T);
        pub const Index = enum(usize) {
            hue = 0,
            saturation = 1,
            luminance = 2,
            alpha = 3,
        };

        pub const Channel = @import("../channel.zig").Channel(Self, T, Index);

        value: Type = @splat(0),

        pub usingnamespace @import("base.zig").Color(Hsl, Self, T);

        pub inline fn channel(self: *const Self, i: Index) *Channel {
            var r = Channel{
                .parent = self,
                .index = i,
            };
            return &r;
        }
    };
}
