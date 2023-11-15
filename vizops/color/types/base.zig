const std = @import("std");

pub fn Color(comptime Factory: fn (comptime type) type, comptime Self: type, comptime T: type) type {
    return struct {
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

        pub inline fn cast(self: Self, comptime V: type) Factory(V) {
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
