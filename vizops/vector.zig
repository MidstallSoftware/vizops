const std = @import("std");
const assert = std.debug.assert;

fn AutoVector(comptime L: usize, comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Int, .Float => Vector(L, T),
        .ComptimeInt => Vector(L, usize),
        .ComptimeFloat => Vector(L, f64),
        .Vector => |v| Vector(v.len, v.child),
        .Pointer => |p| AutoVector(L, p.child),
        .Array => |a| Vector(a.len, a.child),
        .Struct => if (@hasDecl(T, "ElementType") and @hasDecl(T, "Length")) Vector(T.Length, T.ElementType) else @compileError("Incompatible type: " ++ @typeName(T)),
        else => @compileError("Incompatible type: " ++ @typeName(T)),
    };
}

pub fn Vector(comptime VectorLength: usize, comptime _ElementType: type) type {
    if (VectorLength < 2) @compileError("Vector length cannot be less than two");
    return struct {
        const Self = @This();

        pub const ElementType = _ElementType;
        pub const Length = VectorLength;
        pub const Type = @Vector(VectorLength, ElementType);
        pub const ArrayType = [VectorLength]ElementType;

        pub usingnamespace if (VectorLength > 1 and VectorLength < 5)
            struct {
                pub const SizedUp = Vector(VectorLength + 1, ElementType);
                pub const SizedDown = Vector(VectorLength - 1, ElementType);
            }
        else
            struct {};

        pub usingnamespace switch (@typeInfo(ElementType)) {
            .Float, .ComptimeFloat => struct {
                pub const Int8 = Vector(VectorLength, i8);
                pub const Int16 = Vector(VectorLength, i16);
                pub const Int32 = Vector(VectorLength, i32);
                pub const Int64 = Vector(VectorLength, i64);

                pub const Uint8 = Vector(VectorLength, u8);
                pub const Uint16 = Vector(VectorLength, u16);
                pub const Uint32 = Vector(VectorLength, u32);
                pub const Uint64 = Vector(VectorLength, u64);
            },
            .Int, .ComptimeInt => struct {
                pub const Float32 = Vector(VectorLength, f32);
                pub const Float64 = Vector(VectorLength, f64);
                pub const Float128 = Vector(VectorLength, f128);
            },
            else => @compileError("Element type must be a float or integer"),
        };

        value: Type = @splat(0),

        pub inline fn init(value: anytype) Self {
            return switch (@typeInfo(@TypeOf(value))) {
                .ComptimeInt, .Int, .ComptimeFloat, .Float, .Pointer => .{ .value = @splat(value) },
                .Array, .Vector => .{ .value = value },
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(value))),
            };
        }

        pub inline fn zero() Self {
            return .{};
        }

        pub fn dupe(self: Self) Self {
            var c = Self{};
            inline for (self.value, &c.value) |a, *b| {
                b.* = a;
            }
            return c;
        }

        pub inline fn checkIndex(i: anytype) void {
            switch (@typeInfo(@TypeOf(i))) {
                .Int => assert(i > -1 and i < VectorLength),
                .ComptimeInt => if (i < 0 or i >= VectorLength) @compileError("Index is out of range") else void,
                else => @compileError("Invalid type for index"),
            }
        }

        pub inline fn get(self: Self, i: anytype) ElementType {
            checkIndex(i);
            return self.value[i];
        }

        pub inline fn set(self: Self, i: anytype, value: ElementType) void {
            checkIndex(i);
            self.value[i] = value;
        }

        pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) @TypeOf(writer).Error!void {
            _ = fmt;
            _ = options;

            try writer.print("vizops.Vector({}, {s})", .{ VectorLength, @typeName(ElementType) });
            try writer.print("{any}", .{self.value});
        }

        pub fn findTyped(self: Self, comptime T: type, func: *const fn (i: ElementType) ?T) ?T {
            comptime var i: usize = 0;
            inline while (i < VectorLength) : (i += i) {
                const res = func(self.value[i]);
                if (res) |v| return v;
            }
            return null;
        }

        pub fn each(self: Self, func: *const fn (i: ElementType) ElementType) Self {
            var r = zero();
            comptime var i: usize = 0;
            inline while (i < VectorLength) : (i += i) {
                r.value[i] = func(self.value[i]);
            }
            return r;
        }

        pub fn mix(self: Self, b: anytype, func: *const fn (i: ElementType, n: AutoVector(VectorLength, @TypeOf(b)).ElementType) AutoVector(VectorLength, @TypeOf(b)).ElementType) AutoVector(VectorLength, @TypeOf(b)) {
            if (@typeInfo(@TypeOf(b)) == .Pointer) return self.mix(b.*, func);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            var r = ResultType.zero();

            switch (@typeInfo(@TypeOf(b))) {
                .Int, .Float => {
                    comptime var i: usize = 0;
                    inline while (i < ResultType.Length) : (i += 1) {
                        r.value[i] = func(self.value[i], b);
                    }
                },
                .ComptimeInt => {
                    comptime var i: usize = 0;
                    inline while (i < ResultType.Length) : (i += 1) {
                        r.value[i] = func(self.value[i], @as(usize, b));
                    }
                },
                .ComptimeFloat => {
                    comptime var i: usize = 0;
                    inline while (i < ResultType.Length) : (i += 1) {
                        r.value[i] = func(self.value[i], @as(f64, b));
                    }
                },
                .Array, .Vector => {
                    var i: usize = 0;
                    while (i < b.len) : (i += 1) {
                        r.value[i] = func(self.value[i], b[i]);
                    }
                },
                .Struct => {
                    comptime var i: usize = 0;
                    inline while (i < ResultType.Length) : (i += 1) {
                        r.value[i] = func(self.value[i], b.value[i]);
                    }
                },
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            }

            return r;
        }

        pub inline fn mul(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value * b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value * b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x * y;
                }
            }).func);
        }

        pub inline fn div(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value / b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value / b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x / y;
                }
            }).func);
        }

        pub inline fn add(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value + b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value + b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x + y;
                }
            }).func);
        }

        pub inline fn sub(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value - b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value - b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x - y;
                }
            }).func);
        }

        pub inline fn mod(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value % b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value % b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x % y;
                }
            }).func);
        }

        pub inline fn min(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(@min(self.value, b.value));

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(@min(self.value, b));

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return @min(x, y);
                }
            }).func);
        }

        pub inline fn max(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(@max(self.value, b.value));

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(@max(self.value, b));

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return @max(x, y);
                }
            }).func);
        }

        pub inline fn shl(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value << b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value << b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x << y;
                }
            }).func);
        }

        pub inline fn shr(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value >> b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value >> b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x >> y;
                }
            }).func);
        }

        pub inline fn @"and"(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value & b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value & b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x & y;
                }
            }).func);
        }

        pub inline fn @"or"(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value | b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value | b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x | y;
                }
            }).func);
        }

        pub inline fn xor(self: Self, b: anytype) AutoVector(VectorLength, @TypeOf(b)) {
            if (@TypeOf(b) == Self) return init(self.value ^ b.value);

            const ResultType = AutoVector(VectorLength, @TypeOf(b));
            if (ResultType.ElementType == ElementType and ResultType.Length == VectorLength and @typeInfo(@TypeOf(b)) == .Vector) return init(self.value ^ b);

            return mix(self, b, (struct {
                fn func(x: ElementType, y: ResultType.ElementType) ResultType.ElementType {
                    return x ^ y;
                }
            }).func);
        }

        pub inline fn not(self: Self) Self {
            return init(~self.value);
        }

        pub inline fn inv(self: Self) Self {
            return init(-self.value);
        }

        pub inline fn cast(self: Self, comptime T: type) Vector(VectorLength, T) {
            if (T == ElementType) return self;

            var v = Vector(VectorLength, T).zero();

            comptime var i: usize = 0;
            inline while (i < VectorLength) : (i += 1) {
                v.value[i] = switch (@typeInfo(T)) {
                    .Int => @intCast(self.value[i]),
                    .Float => @floatCast(self.value[i]),
                    else => @compileError("Incompatible type: " ++ @typeName(T)),
                };
            }

            return v;
        }

        pub inline fn eq(self: Self, b: anytype) bool {
            return switch (@typeInfo(@TypeOf(b))) {
                .Pointer => self.eq(b.*),
                .Int, .Float, .Vector, .Array => self.eq(init(b)),
                .Struct => std.simd.countTrues(self.value == b.value) == VectorLength,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };
        }

        pub inline fn lt(self: Self, b: anytype) bool {
            return switch (@typeInfo(@TypeOf(b))) {
                .Pointer => self.lt(b.*),
                .Int, .Float, .Vector, .Array => self.lt(init(b)),
                .Struct => std.simd.countTrues(self.value < b.value) == VectorLength,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };
        }

        pub inline fn gt(self: Self, b: anytype) bool {
            return switch (@typeInfo(@TypeOf(b))) {
                .Pointer => self.gt(b.*),
                .Int, .Float, .Vector, .Array => self.gt(init(b)),
                .Struct => std.simd.countTrues(self.value > b.value) == VectorLength,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };
        }

        pub inline fn lteq(self: Self, b: anytype) bool {
            return switch (@typeInfo(@TypeOf(b))) {
                .Pointer => self.lteq(b.*),
                .Int, .Float, .Vector, .Array => self.lteq(init(b)),
                .Struct => std.simd.countTrues(self.value <= b.value) == VectorLength,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };
        }

        pub inline fn gteq(self: Self, b: anytype) bool {
            return switch (@typeInfo(@TypeOf(b))) {
                .Pointer => self.gteq(b.*),
                .Int, .Float, .Vector, .Array => self.gteq(init(b)),
                .Struct => std.simd.countTrues(self.value >= b.value) == VectorLength,
                else => @compileError("Incompatible type: " ++ @typeName(@TypeOf(b))),
            };
        }
    };
}

pub fn TypedVector(comptime ElementType: type) fn (comptime usize) type {
    return (struct {
        fn func(comptime VectorLength: usize) type {
            return Vector(VectorLength, ElementType);
        }
    }).func;
}

pub fn SizedVector(comptime VectorLength: usize) fn (comptime type) type {
    return (struct {
        fn func(comptime ElementType: type) type {
            return Vector(VectorLength, ElementType);
        }
    }).func;
}

// Typed vectors

pub const Float32Vector = TypedVector(f32);
pub const Float64Vector = TypedVector(f64);
pub const Float128Vector = TypedVector(f128);

pub const Int8Vector = TypedVector(i8);
pub const Int16Vector = TypedVector(i16);
pub const Int32Vector = TypedVector(i32);
pub const Int64Vector = TypedVector(i64);
pub const IsizeVector = TypedVector(isize);

pub const Uint8Vector = TypedVector(u8);
pub const Uint16Vector = TypedVector(u16);
pub const Uint32Vector = TypedVector(u32);
pub const Uint64Vector = TypedVector(u64);
pub const UsizeVector = TypedVector(usize);

// Sized vectors

pub const Vector2 = SizedVector(2);
pub const Vector3 = SizedVector(3);
pub const Vector4 = SizedVector(4);

// Complete vectors

pub const Float32Vector2 = Float32Vector(2);
pub const Float32Vector3 = Float32Vector(3);
pub const Float32Vector4 = Float32Vector(4);

pub const Float64Vector2 = Float64Vector(2);
pub const Float64Vector3 = Float64Vector(3);
pub const Float64Vector4 = Float64Vector(4);

pub const Float128Vector2 = Float128Vector(2);
pub const Float128Vector3 = Float128Vector(3);
pub const Float128Vector4 = Float128Vector(4);

pub const Int8Vector2 = Int8Vector(2);
pub const Int8Vector3 = Int8Vector(3);
pub const Int8Vector4 = Int8Vector(4);

pub const Int16Vector2 = Int16Vector(2);
pub const Int16Vector3 = Int16Vector(3);
pub const Int16Vector4 = Int16Vector(4);

pub const Int32Vector2 = Int32Vector(2);
pub const Int32Vector3 = Int32Vector(3);
pub const Int32Vector4 = Int32Vector(4);

pub const Int64Vector2 = Int64Vector(2);
pub const Int64Vector3 = Int64Vector(3);
pub const Int64Vector4 = Int64Vector(4);

pub const IsizeVector2 = IsizeVector(2);
pub const IsizeVector3 = IsizeVector(3);
pub const IsizeVector4 = IsizeVector(4);

pub const Uint8Vector2 = Uint8Vector(2);
pub const Uint8Vector3 = Uint8Vector(3);
pub const Uint8Vector4 = Uint8Vector(4);

pub const Uint16Vector2 = Uint16Vector(2);
pub const Uint16Vector3 = Uint16Vector(3);
pub const Uint16Vector4 = Uint16Vector(4);

pub const Uint32Vector2 = Uint32Vector(2);
pub const Uint32Vector3 = Uint32Vector(3);
pub const Uint32Vector4 = Uint32Vector(4);

pub const Uint64Vector2 = Uint64Vector(2);
pub const Uint64Vector3 = Uint64Vector(3);
pub const Uint64Vector4 = Uint64Vector(4);

pub const UsizeVector2 = UsizeVector(2);
pub const UsizeVector3 = UsizeVector(3);
pub const UsizeVector4 = UsizeVector(4);
