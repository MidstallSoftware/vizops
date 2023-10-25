const std = @import("std");
const assert = std.debug.assert;

pub fn Vector(comptime VectorLength: usize, comptime ElementType: type) type {
    if (VectorLength < 2) @compileError("Vector length cannot be less than two");
    return struct {
        const Self = @This();

        pub const Type = @Vector(VectorLength, ElementType);

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

        value: Type = Type{0} ** VectorLength,

        pub fn init(value: Type) Self {
            return .{
                .value = value,
            };
        }

        pub fn zero() Self {
            return .{};
        }

        pub fn dupe(self: Self) Self {
            var c = Self{};
            inline for (self.value, &c.value) |a, *b| {
                b.* = a;
            }
            return c;
        }

        pub fn setSizedReturn(self: Self, b: Self, comptime ReturnType: type, comptime ReturnLength: usize, func: *const fn (i: ElementType, n: ElementType) ElementType) Vector(ReturnLength, ReturnType) {
            var c = Vector(ReturnLength, ReturnType).zero();
            inline for (&c.value, 0..) |*z, i| {
                const x = self.value[i];
                const y = b.value[i];

                z.* = func(x, y);
            }
            return c;
        }

        pub inline fn setSized(self: Self, b: Self, comptime ReturnLength: usize, func: *const fn (i: ElementType, n: ElementType) ElementType) Vector(ReturnLength, ElementType) {
            return setSizedReturn(self, b, ElementType, ReturnLength, func);
        }

        pub inline fn setReturn(self: Self, b: Self, comptime ReturnType: type, func: *const fn (i: ElementType, n: ElementType) ReturnType) Vector(VectorLength, ReturnType) {
            return setSizedReturn(self, b, ReturnType, VectorLength, func);
        }

        pub inline fn set(self: Self, b: Self, func: *const fn (i: ElementType, n: ElementType) ElementType) Self {
            return setSized(self, b, ElementType, VectorLength, func);
        }

        pub fn mul(self: Self, b: Self) Self {
            return set(self, b, (struct {
                fn func(x: ElementType, y: ElementType) ElementType {
                    return x * y;
                }
            }).func);
        }

        pub fn div(self: Self, b: Self) Self {
            return set(self, b, (struct {
                fn func(x: ElementType, y: ElementType) ElementType {
                    return x / y;
                }
            }).func);
        }

        pub fn add(self: Self, b: Self) Self {
            return set(self, b, (struct {
                fn func(x: ElementType, y: ElementType) ElementType {
                    return x + y;
                }
            }).func);
        }

        pub fn sub(self: Self, b: Self) Self {
            return set(self, b, (struct {
                fn func(x: ElementType, y: ElementType) ElementType {
                    return x - y;
                }
            }).func);
        }

        pub fn mod(self: Self, b: Self) Self {
            return set(self, b, (struct {
                fn func(x: ElementType, y: ElementType) ElementType {
                    return x % y;
                }
            }).func);
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

pub const Uint8Vector = TypedVector(u8);
pub const Uint16Vector = TypedVector(u16);
pub const Uint32Vector = TypedVector(u32);
pub const Uint64Vector = TypedVector(u64);

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
