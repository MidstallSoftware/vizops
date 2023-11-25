const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const FourccValue = @import("../fourcc/value.zig").Value;

pub fn sRGB(comptime T: type) type {
    return struct {
        const ColorFormats = @import("../typed.zig").Typed(T);
        const ColorFormatUnion = @import("../typed.zig").Union(T);
        const ColorFormatType = std.meta.DeclEnum(ColorFormats);
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

        pub inline fn readBuffer(format: FourccValue, buff: []u8) !Self {
            const IntType = if (@typeInfo(T) == .Float) @Type(.{
                .Int = .{
                    .signedness = .unsigned,
                    .bits = @typeInfo(T).Float.bits,
                },
            }) else T;

            return sRGB(IntType).read(format, std.mem.bytesAsSlice(IntType, if (@typeInfo(T) == .Float) @bitCast(buff) else buff)).cast(T);
        }

        pub fn read(format: FourccValue, value: []T) !Self {
            const channels = format.channelCount();
            if (value.len < channels) return error.InvalidChannels;

            if (@typeInfo(T) == .Float and format.has(.float)) {
                return switch (format) {
                    .argb_f => Self.init(.{ value[1], value[2], value[3], value[0] }),
                    .abgr_f => Self.init(.{ value[1], value[3], value[2], value[0] }),
                    .xrgb_f => Self.init(.{ value[1], value[2], value[3], 1.0 }),
                    .xbgr_f => Self.init(.{ value[3], value[2], value[1], 1.0 }),
                    else => return error.InvalidFormat,
                };
            }

            if (@typeInfo(T) == .Int and !format.has(.float)) {
                const fullAlpha = std.math.maxInt(T);
                return switch (format) {
                    .r => Self.init(.{ value[0], 0, 0, fullAlpha }),
                    .rg => Self.init(.{ value[0], value[1], 0, fullAlpha }),
                    .gr => Self.init(.{ value[1], value[0], 0, fullAlpha }),
                    .rgb => Self.init(.{ value[0], value[1], value[2], fullAlpha }),
                    .bgr => Self.init(.{ value[2], value[1], value[0], fullAlpha }),
                    .xrgb => Self.init(.{ value[1], value[2], value[3], fullAlpha }),
                    .xbgr => Self.init(.{ value[3], value[2], value[1], fullAlpha }),
                    .rgba => Self.init(.{ value[0], value[1], value[2], value[3] }),
                    .rgbx => Self.init(.{ value[0], value[1], value[2], fullAlpha }),
                    .bgrx => Self.init(.{ value[2], value[1], value[0], fullAlpha }),
                    .argb => Self.init(.{ value[1], value[2], value[3], value[0] }),
                    .abgr => Self.init(.{ value[3], value[2], value[1], value[0] }),
                    .bgra => Self.init(.{ value[2], value[1], value[0], value[3] }),
                    .xrgb_a => Self.init(.{ value[1], value[2], value[3], fullAlpha }),
                    .xbgr_a => Self.init(.{ value[3], value[2], value[1], fullAlpha }),
                    .rgbx_a => Self.init(.{ value[0], value[2], value[3], fullAlpha }),
                    .bgrx_a => Self.init(.{ value[2], value[1], value[0], fullAlpha }),
                    .axbxgxrx => Self.init(.{ value[6], value[4], value[2], value[0] }),
                    else => return error.InvalidFormat,
                };
            }
            return error.InvalidType;
        }

        pub inline fn writeBuffer(self: Self, format: FourccValue, buff: []u8) !void {
            const IntType = if (@typeInfo(T) == .Float) @Type(.{
                .Int = .{
                    .signedness = .unsigned,
                    .bits = @typeInfo(T).Float.bits,
                },
            }) else T;

            try self.cast(IntType).write(format, std.mem.bytesAsSlice(IntType, buff));
        }

        pub inline fn allocWrite(self: Self, alloc: Allocator, format: FourccValue) ![]T {
            const buf = try alloc.alloc(T, format.channelCount());
            errdefer alloc.free(buf);

            try self.write(format, buf);
            return buf;
        }

        pub fn write(self: Self, format: FourccValue, value: []T) !void {
            const channels = format.channelCount();
            if (value.len < channels) return error.InvalidChannels;

            if (@typeInfo(T) == .Float and format.has(.float)) {
                switch (format) {
                    .argb_f => value[0..4].* = [4]T{ self.value[3], self.value[0], self.value[1], self.value[2] },
                    .abgr_f => value[0..4].* = [4]T{ self.value[3], self.value[2], self.value[1], self.value[0] },
                    .xrgb_f => value[0..4].* = [4]T{ 0, self.value[0], self.value[1], self.value[2] },
                    .xbgr_f => value[0..4].* = [4]T{ 0, self.value[2], self.value[1], self.value[0] },
                    else => return error.InvalidFormat,
                }
                return;
            }

            if (@typeInfo(T) == .Int and !format.has(.float)) {
                switch (format) {
                    .r => value[0] = self.value[0],
                    .rg => @memcpy(value[0..2], &[2]T{ self.value[0], self.value[1] }),
                    .gr => @memcpy(value[0..2], &[2]T{ self.value[1], self.value[0] }),
                    .rgb => @memcpy(value[0..3], &[3]T{ self.value[0], self.value[1], self.value[2] }),
                    .bgr => @memcpy(value[0..3], &[3]T{ self.value[2], self.value[1], self.value[0] }),
                    .xrgb => @memcpy(value[0..4], &[4]T{ 0, self.value[0], self.value[1], self.value[2] }),
                    .xbgr => @memcpy(value[0..4], &[4]T{ 0, self.value[2], self.value[1], self.value[0] }),
                    .rgba => @memcpy(value[0..4], &[4]T{ self.value[0], self.value[1], self.value[2], self.value[3] }),
                    .rgbx => @memcpy(value[0..4], &[4]T{ self.value[0], self.value[1], self.value[2], 0 }),
                    .bgrx => @memcpy(value[0..4], &[4]T{ self.value[2], self.value[1], self.value[0], 0 }),
                    .argb => @memcpy(value[0..4], &[4]T{ self.value[3], self.value[0], self.value[1], self.value[2] }),
                    .abgr => @memcpy(value[0..4], &[4]T{ self.value[3], self.value[2], self.value[1], self.value[0] }),
                    .bgra => @memcpy(value[0..4], &[4]T{ self.value[2], self.value[1], self.value[0], self.value[3] }),
                    .xrgb_a => @memcpy(value[0..5], &[5]T{ 0, self.value[0], self.value[1], self.value[2], 0 }),
                    .xbgr_a => @memcpy(value[0..5], &[5]T{ 0, self.value[2], self.value[1], self.value[0], 0 }),
                    .rgbx_a => @memcpy(value[0..5], &[5]T{ self.value[0], self.value[1], self.value[2], 0, 0 }),
                    .bgrx_a => @memcpy(value[0..5], &[5]T{ self.value[2], self.value[1], self.value[0], 0, 0 }),
                    .axbxgxrx => @memcpy(value[0..8], &[8]T{ self.value[3], 0, self.value[2], 0, self.value[1], 0, self.value[0], 0 }),
                    else => return error.InvalidFormat,
                }
                return;
            }
            return error.InvalidType;
        }

        pub fn convert(self: Self, t: ColorFormatType) ColorFormatUnion {
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
