const std = @import("std");

pub fn Color(comptime Factory: fn (comptime type) type, comptime Self: type, comptime T: type) type {
    const VectorLength = @typeInfo(Self.Type).Vector.len;
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

        pub inline fn inv(self: Self) Self {
            var val: @Vector(T, VectorLength) = @splat(0);
            const max = if (@typeInfo(T) == .Float) @as(T, 1.0) else std.math.maxInt(T);

            comptime var i: usize = 0;
            inline while (i < VectorLength) : (i += 1) {
                val[i] = max - self.value[i];
            }
            return val;
        }

        pub inline fn cast(self: Self, comptime V: type) Factory(V) {
            if (V == T) return self;
            if (@typeInfo(V) == .Float and @typeInfo(T) == .Float) {
                var vector: @Vector(VectorLength, V) = undefined;
                inline for (0..VectorLength) |i| vector[i] = @floatCast(self.value[i]);
                return .{
                    .value = vector,
                };
            }

            if (@typeInfo(V) == .Int and @typeInfo(T) == .Int) {
                return self.cast(std.meta.Float(@typeInfo(V).Int.bits)).cast(V);
            }

            const IntType = if (@typeInfo(V) == .Int) V else T;
            const FloatType = if (@typeInfo(V) == .Float) V else T;
            const max: FloatType = @floatFromInt(std.math.maxInt(IntType));

            var vector: @Vector(VectorLength, V) = undefined;
            inline for (0..VectorLength) |i| {
                vector[i] = if (IntType == V) @intFromFloat(self.value[i] * max) else @floatFromInt(self.value[i]);
            }

            return .{
                .value = if (FloatType == V) vector / @as(@Vector(VectorLength, V), @splat(max)) else vector,
            };
        }

        pub inline fn eq(self: Self, b: anytype) bool {
            const bvalue = switch (@typeInfo(@TypeOf(b))) {
                .Pointer => b.*,
                .Int, .Float, .Vector, .Array => init(b).value,
                .Struct => |s| if (s.is_tuple) init(b).value else b.value,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };

            return std.simd.countTrues(self.value == bvalue) == @typeInfo(Self.Type).Vector.len;
        }
    };
}
