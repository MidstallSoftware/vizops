const std = @import("std");
const types = @This();

pub const Type = blk: {
    const t = @typeInfo(std.meta.DeclEnum(@This())).Enum;
    break :blk @Type(.{
        .Enum = .{
            .tag_type = t.tag_type,
            .fields = t.fields[1..],
            .decls = &.{},
            .is_exhaustive = t.is_exhaustive,
        },
    });
};

fn f(comptime T: type, t: T) T {
    const t2 = std.math.lossyCast(f64, t);
    const limit = @reduce(.Mul, @as(@Vector(3, f64), @splat(24.0 / 116.0)));
    return std.math.lossyCast(T, if (t2 <= limit) (841.0 / 108.0) * t2 + (16.0 / 116.0) else std.math.pow(f64, t2, 1.0 / 3.0));
}

fn f1(comptime T: type, t: T) T {
    const t2 = std.math.lossyCast(f64, t);
    const limit = 24.0 / 116.0;
    return std.math.lossyCast(T, if (t2 < limit) (108.0 / 841.0) * (t2 - (16.0 / 116.0)) else @reduce(.Mul, @as(@Vector(3, f64), @splat(t2))));
}

fn atan2deg(comptime T: type, a: T, b: T) T {
    var h = std.math.lossyCast(f64, if (a == 0 and b == 0) @as(T, 0) else std.math.atan2(T, a, b));

    h *= 180 / @as(f64, std.math.pi);

    while (h > 360.0) h -= 360.0;
    while (h < 0) h += 360.0;
    return std.math.lossyCast(T, h);
}

pub fn xyz(comptime T: type) type {
    return struct {
        const Vector = @Vector(3, T);
        const Self = @This();

        pub const D50 = Self{
            .value = .{ 0.9642, 1.0, 0.8249 },
        };

        value: Vector,

        pub fn convert(self: Self, comptime to: Type) @field(types, @tagName(to))(T) {
            const X = @field(types, @tagName(to))(T);
            return switch (to) {
                .xyz => self,
                .xyY => blk: {
                    const isum = 1.0 / @reduce(.Add, self.value);
                    break :blk X{
                        .value = .{
                            self.value[0] * isum,
                            self.value[1] * isum,
                            self.value[1],
                        },
                    };
                },
                .lab => self.convert(.xyY).convert(.lab),
                .lch => self.convert(.lab).convert(.lch),
            };
        }

        pub fn cast(self: Self, comptime X: type) xyz(X) {
            var value: @Vector(3, X) = @splat(0);
            comptime var i: usize = 0;
            inline while (i < 3) : (i += 1) {
                value[i] = std.math.lossyCast(X, self.value[i]);
            }
            return .{
                .value = value,
            };
        }

        pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            return writer.print("vizops.color.types.xyz({s}){}", .{ @typeName(T), self.value });
        }
    };
}

pub fn xyY(comptime T: type) type {
    return struct {
        const Vector = @Vector(3, T);
        const Self = @This();

        pub const D50 = xyz(T).D50.convert(.xyY);

        value: Vector,

        pub fn convert(self: Self, comptime to: Type) @field(types, @tagName(to))(T) {
            const X = @field(types, @tagName(to))(T);
            return switch (to) {
                .xyz => X{
                    .value = .{
                        (self.value[0] / self.value[1]) * self.value[2],
                        self.value[2],
                        ((1 - self.value[1] - self.value[2]) / self.value[1]) * self.value[2],
                    },
                },
                .xyY => self,
                .lab => blk: {
                    var fv: @Vector(3, T) = self.value / D50.value;
                    comptime var i: usize = 0;
                    inline while (i < 3) : (i += 1) fv[i] = f(T, fv[i]);

                    break :blk X{
                        .value = .{
                            116.0 * fv[1] - 16.0,
                            500.0 * (fv[0] - fv[1]),
                            200.0 * (fv[1] - fv[2]),
                        },
                    };
                },
                .lch => self.convert(.lab).convert(.lch),
            };
        }

        pub fn cast(self: Self, comptime X: type) xyY(X) {
            var value: @Vector(3, X) = @splat(0);
            comptime var i: usize = 0;
            inline while (i < 3) : (i += 1) {
                value[i] = std.math.lossyCast(X, self.value[i]);
            }
            return .{
                .value = value,
            };
        }

        pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            return writer.print("vizops.color.types.xyY({s}){}", .{ @typeName(T), self.value });
        }
    };
}

pub fn lab(comptime T: type) type {
    return struct {
        const Vector = @Vector(3, T);
        const Self = @This();

        value: Vector,

        pub fn convert(self: Self, comptime to: Type) @field(types, @tagName(to))(T) {
            const X = @field(types, @tagName(to))(T);
            return switch (to) {
                .xyz => blk: {
                    const y = (self.value[0] + 16.0) / 116.0;
                    const x = y + 0.002 * self.value[1];
                    const z = y - 0.005 * self.value[2];

                    break :blk X{
                        .value = (X.Vector{ f1(T, x), f1(T, y), f1(T, z) }) * X.D50.value,
                    };
                },
                .xyY => self.convert(.xyz).convert(.xyY),
                .lab => self,
                .lch => X{
                    .value = .{ self.value[0], std.math.pow(T, (self.value[1] * self.value[1]) + (self.value[2] * self.value[2]), 0.5), atan2deg(T, self.value[1], self.value[2]) },
                },
            };
        }

        pub fn cast(self: Self, comptime X: type) lab(X) {
            var value: @Vector(3, X) = @splat(0);
            comptime var i: usize = 0;
            inline while (i < 3) : (i += 1) {
                value[i] = std.math.lossyCast(X, self.value[i]);
            }
            return .{
                .value = value,
            };
        }

        pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            return writer.print("vizops.color.types.lab({s}){}", .{ @typeName(T), self.value });
        }
    };
}

pub fn lch(comptime T: type) type {
    return struct {
        const Vector = @Vector(3, T);
        const Self = @This();

        value: Vector,

        pub fn convert(self: Self, comptime to: Type) @field(types, @tagName(to))(T) {
            const X = @field(types, @tagName(to))(T);
            return switch (to) {
                .lab => blk: {
                    const h = (self.value[2] * std.math.pi) / 180.0;

                    break :blk X{
                        .value = .{
                            self.value[0],
                            self.value[1] * std.math.cos(h),
                            self.value[1] * std.math.sin(h),
                        },
                    };
                },
                else => @compileError("Invalid conversion of lch to " ++ @tagName(to)),
            };
        }

        pub fn cast(self: Self, comptime X: type) lab(X) {
            var value: @Vector(3, X) = @splat(0);
            comptime var i: usize = 0;
            inline while (i < 3) : (i += 1) {
                value[i] = std.math.lossyCast(X, self.value[i]);
            }
            return .{
                .value = value,
            };
        }

        pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            return writer.print("vizops.color.types.lch({s}){}", .{ @typeName(T), self.value });
        }
    };
}
