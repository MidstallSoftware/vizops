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

        pub const Channel = struct {
            ptr: *const Self,
            index: Index,
            data: ?T = null,

            pub inline fn value(self: Channel) T {
                return self.data orelse self.ptr.value[@intFromEnum(self.index)];
            }

            pub inline fn set(self: *Channel, v: T) *Channel {
                self.data = v;
                return self;
            }

            pub inline fn add(self: *Channel, v: T) *Channel {
                return self.set(self.value() + v);
            }

            pub inline fn sub(self: *Channel, v: T) *Channel {
                return self.set(self.value() - v);
            }

            pub inline fn mul(self: *Channel, v: T) *Channel {
                return self.set(self.value() * v);
            }

            pub inline fn div(self: *Channel, v: T) *Channel {
                return self.set(self.value() / v);
            }

            pub inline fn done(self: *Channel) Self {
                var vec = self.ptr.value;
                vec[@intFromEnum(self.index)] = self.value();
                return .{
                    .value = vec,
                };
            }
        };

        value: Type = @splat(0),

        pub inline fn init(value: anytype) Self {
            return switch (@typeInfo(@TypeOf(value))) {
                .ComptimeInt, .Int, .ComptimeFloat, .Float, .Pointer => .{ .value = @splat(value) },
                .Array, .Vector => .{ .value = value },
                .Struct => |s| if (s.is_tuple) blk: {
                    var val: @Vector(s.fields.len, T) = @splat(0);
                    inline for (s.fields, 0..) |f, i| {
                        val[i] = @field(value, f.name);
                    }
                    break :blk .{ .value = val };
                } else value,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(value))),
            };
        }

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
            };
        }

        pub inline fn channel(self: *const Self, i: Index) *Channel {
            var r = Channel{
                .ptr = self,
                .index = i,
            };
            return &r;
        }

        pub inline fn cast(self: Self, comptime V: type) sRGB(V) {
            if (V == T) return self;
            if (@typeInfo(V) == .Float and @typeInfo(T) == .Float) {
                return .{
                    .value = [_]V{
                        @floatCast(self.value[0]),
                        @floatCast(self.value[1]),
                        @floatCast(self.value[2]),
                        @floatCast(self.value[3]),
                    },
                };
            }

            if (@typeInfo(V) == .Int and @typeInfo(T) == .Int) {
                return self.cast(std.meta.Float(@typeInfo(V).Int.bits)).cast(V);
            }

            const IntType = if (@typeInfo(V) == .Int) V else T;
            const FloatType = if (@typeInfo(V) == .Float) V else T;
            const max: FloatType = @floatFromInt(std.math.maxInt(IntType));
            return if (IntType == V) .{
                .value = .{
                    @as(V, @intFromFloat(self.value[0] * max)),
                    @as(V, @intFromFloat(self.value[1] * max)),
                    @as(V, @intFromFloat(self.value[2] * max)),
                    @as(V, @intFromFloat(self.value[3] * max)),
                },
            } else .{
                .value = (@Vector(4, V){
                    @as(V, @floatFromInt(self.value[0])),
                    @as(V, @floatFromInt(self.value[1])),
                    @as(V, @floatFromInt(self.value[2])),
                    @as(V, @floatFromInt(self.value[3])),
                }) / @as(@Vector(4, V), @splat(max)),
            };
        }
    };
}

pub const sRGBu8 = sRGB(u8);
pub const sRGBf32 = sRGB(f32);
