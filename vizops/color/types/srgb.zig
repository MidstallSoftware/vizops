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

                    const h = @mod(((blk2: {
                        if (cmax == value[0]) break :blk2 (value[1] - value[2]) / delta;
                        if (cmax == value[1]) break :blk2 2.0 + ((value[2] - value[0]) / delta);
                        break :blk2 4.0 + ((value[0] - value[1]) / delta);
                    }) * 60), 360) / 365;

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
                    const l = (cmax + cmin) / 2.0;
                    const a = value[3];

                    if (cmin == cmax) {
                        break :blk .{ .hsl = @import("hsl.zig").Hsl(f32).init(.{ 0, 0, l, a }).cast(T) };
                    }

                    const delta: V = cmax - cmin;

                    const h = @mod(((blk2: {
                        if (cmax == value[0]) break :blk2 (value[1] - value[2]) / delta;
                        if (cmax == value[1]) break :blk2 2.0 + ((value[2] - value[0]) / delta);
                        break :blk2 4.0 + ((value[0] - value[1]) / delta);
                    }) * 60), 360) / 365;

                    const s = if (delta == 0) 0 else delta / (1 - @abs(2 * l - 1));

                    break :blk .{ .hsl = @import("hsl.zig").Hsl(f32).init(.{ h, s, l, a }).cast(T) };
                },
                .cmyk => blk: {
                    const V = if (@typeInfo(T) == .Int) f32 else T;
                    const value = self.cast(V).value;
                    const arrval: [4]V = value;
                    const rgb: @Vector(3, V) = arrval[0..3].*;

                    const k = 1 - @max(value[0], value[1], value[2]);
                    const cmy = (@as(@Vector(3, V), @splat(1)) - rgb - @as(@Vector(3, V), @splat(k))) / @as(@Vector(3, V), @splat(1 - k));

                    break :blk .{ .cmyk = @import("cmyk.zig").Cmyk(V).init(std.simd.join(cmy, @Vector(2, V){ k, value[3] })).cast(T) };
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

inline fn rad(v: u16) u8 {
    return @intFromFloat((@as(f32, @floatFromInt(v)) / 365.0) * 255.0);
}

test "Common colors from sRGB to HSL" {
    const table: []const struct { @Vector(4, u8), @Vector(4, u8) } = &.{
        // #000
        .{ @splat(0), @splat(0) },
        // #fff
        .{ @splat(255), .{ 0, 0, 255, 255 } },
        // #f00
        .{
            .{ 255, 0, 0, 255 },
            .{ 0, 255, @as(u8, 255 / 2), 255 },
        },
        // #0f0
        .{
            .{ 0, 255, 0, 255 },
            .{ rad(120), 255, @as(u8, 255 / 2), 255 },
        },
        // #00f
        .{
            .{ 0, 0, 255, 255 },
            .{ rad(240), 255, @as(u8, 255 / 2), 255 },
        },
        // #ff0
        .{
            .{ 255, 255, 0, 255 },
            .{ rad(60), 255, @as(u8, 255 / 2), 255 },
        },
        // #0ff
        .{
            .{ 0, 255, 255, 255 },
            .{ rad(180), 255, @as(u8, 255 / 2), 255 },
        },
        // #f0f
        .{
            .{ 255, 0, 255, 255 },
            .{ rad(300), 255, @as(u8, 255 / 2), 255 },
        },
        // #bfbfbf
        .{
            .{ 191, 191, 191, 255 },
            .{ 0, 0, 191, 255 },
        },
        // #808080
        .{
            .{ 128, 128, 128, 255 },
            .{ 0, 0, 128, 255 },
        },
        // #800
        .{
            .{ 128, 0, 0, 255 },
            .{ 0, 255, 64, 255 },
        },
        // #808000
        .{
            .{ 128, 128, 0, 255 },
            .{ rad(60), 255, 64, 255 },
        },
        // #080
        .{
            .{ 0, 128, 0, 255 },
            .{ rad(120), 255, 64, 255 },
        },
        // #800080
        .{
            .{ 128, 0, 128, 255 },
            .{ rad(300), 255, 64, 255 },
        },
        // #008080
        .{
            .{ 0, 128, 128, 255 },
            .{ rad(180), 255, 64, 255 },
        },
        // #008
        .{
            .{ 0, 0, 128, 255 },
            .{ rad(240), 255, 64, 255 },
        },
    };

    for (table, 0..) |entry, i| {
        const value = sRGBu8.init(entry[0]).convert(.hsl).hsl.value;
        const expected = @import("hsl.zig").Hsl(u8).init(entry[1]).value;
        std.testing.expectEqual(expected, value) catch |err| {
            std.debug.print("(#{}) value: {}, expected: {}\n", .{ i, value, expected });
            return err;
        };
    }
}
