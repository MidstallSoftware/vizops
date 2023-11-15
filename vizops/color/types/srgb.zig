const std = @import("std");
const metaplus = @import("meta+");

pub fn sRGB(comptime T: type) type {
    return struct {
        const ColorFormats = @import("../typed.zig").Typed(T);
        const ColorFormatType = std.meta.DeclEnum(ColorFormats);
        const ColorFormatUnion = metaplus.unions.useTag(metaplus.unions.fromDecls(ColorFormats), ColorFormatType);
        const Self = @This();

        pub const Type = @Vector(4, T);
        pub const Index = enum(usize) {
            red = 0,
            green = 1,
            blue = 2,
            alpha = 3,
        };

        pub const Channel = @import("../channel.zig").Channel(Self, T, Index);

        value: Type = @splat(0),

        pub usingnamespace @import("base.zig").Color(sRGB, Self, T);

        pub inline fn convert(self: Self, t: ColorFormatType) ColorFormatUnion {
            return switch (t) {
                .sRGB => .{ .sRGB = self },
                .linearRGB => blk: {
                    const V = if (@typeInfo(T) == .Float) u16 else T;

                    const lut = comptime blk2: {
                        @setEvalBranchQuota(1_000 * std.math.maxInt(V));
                        const max = std.math.maxInt(V);
                        var res: [max + 1]f32 = undefined;
                        for (0..(max + 1)) |i| {
                            const c = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(max));
                            res[i] = if (c <= 0.04045) c / 12.92 else std.math.pow(f32, (c + 0.055) / 1.055, 2.4);
                        }
                        break :blk2 res;
                    };

                    const value = self.cast(V).value;

                    break :blk .{ .linearRGB = @import("linear-rgb.zig").linearRGB(f32).init(.{
                        lut[value[0]],
                        lut[value[1]],
                        lut[value[2]],
                        lut[value[3]],
                    }).cast(T) };
                },
                .hsv => blk: {
                    const V = if (@typeInfo(T) == .Int) f32 else T;
                    const value = self.cast(V).value;

                    const cmax = @max(value[0], value[1], value[2]);
                    const cmin = @min(value[0], value[1], value[2]);
                    const delta: V = cmax - cmin;

                    const h = blk2: {
                        if (delta == 0) break :blk2 0;
                        if (cmax == value[0]) break :blk2 @mod((@mod(((value[1] - value[2]) / delta), @as(V, 6.0)) * 60.0), 360.0);
                        if (cmax == value[1]) break :blk2 @mod(((((value[2] - value[0]) / delta) + 2.0) * 60.0), 360.0);
                        if (cmax == value[2]) break :blk2 @mod(((((value[0] - value[1]) / delta) + 4.0) * 60.0), 360.0);
                        unreachable;
                    };

                    const s = if (cmax == 0) 0 else delta / cmax;
                    const v = cmax;
                    const a = value[3];

                    break :blk .{ .hsv = @import("hsv.zig").Hsv(f32).init(.{ h, s, v, a }).cast(T) };
                },
                .hsl => blk: {
                    const V = if (@typeInfo(T) == .Int) f32 else T;
                    const value = self.cast(V).value;

                    const cmax = @max(value[0], value[1], value[2]);
                    const cmin = @min(value[0], value[1], value[2]);
                    const delta: V = cmax - cmin;

                    const h = blk2: {
                        if (delta == 0) break :blk2 0;
                        if (cmax == value[0]) break :blk2 @mod((@mod(((value[1] - value[2]) / delta), @as(V, 6.0)) * 60.0), 360.0);
                        if (cmax == value[1]) break :blk2 @mod(((((value[2] - value[0]) / delta) + 2.0) * 60.0), 360.0);
                        if (cmax == value[2]) break :blk2 @mod(((((value[0] - value[1]) / delta) + 4.0) * 60.0), 360.0);
                        unreachable;
                    };

                    const l = (cmax + cmin) / 2;
                    const s = if (delta == 0) 0 else delta / (1 - @abs(2 * l - 1));
                    const a = value[3];

                    break :blk .{ .hsl = @import("hsl.zig").Hsl(f32).init(.{ h, s, l, a }).cast(T) };
                },
            };
        }

        pub inline fn channel(self: *const Self, i: Index) *Channel {
            var r = Channel{
                .parent = self,
                .index = i,
            };
            return &r;
        }
    };
}

pub const sRGBu8 = sRGB(u8);
pub const sRGBf32 = sRGB(f32);
