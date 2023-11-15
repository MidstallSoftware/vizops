const std = @import("std");
const metaplus = @import("meta+");

pub fn sRGB(comptime T: type) type {
    return struct {
        const ColorFormats = @import("../typed.zig").Typed(T);
        const ColorFormatType = std.meta.DeclEnum(ColorFormats);
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
                    var i: usize = 0;
                    inline while (i < s.fields.len) : (i += 1) {
                        val[i] = @field(value, s.fields[i].name);
                    }
                    break :blk val;
                } else value,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(value))),
            };
        }

        pub inline fn convert(self: Self, t: ColorFormatType) metaplus.unions.fromDecls(ColorFormats) {
            return switch (t) {
                .sRGB => self,
            };
        }

        pub inline fn channel(self: *const Self, i: Index) *Channel {
            var r = Channel{
                .ptr = self,
                .index = i,
            };
            return &r;
        }
    };
}

pub const sRGBu8 = sRGB(u8);
pub const sRGBf32 = sRGB(f32);
