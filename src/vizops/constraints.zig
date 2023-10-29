const std = @import("std");
const testing = std.testing;

const metaplus = @import("meta+");
const vector = @import("vector.zig");

pub fn Size(comptime Length: usize, comptime T: type) type {
    return struct {
        const Self = @This();
        const Vector = vector.Vector(Length, T);

        horiz: Vector = .{},
        vert: Vector = .{},
    };
}

pub fn VectorConstraint(comptime Length: usize, comptime T: type) type {
    return struct {
        const Self = @This();
        const Vector = vector.Vector(Length, T);
        const _Size = Size(Length, T);

        min: ?Vector,
        max: ?Vector,

        pub fn tight(size: _Size, axis: metaplus.enums.fromFields(_Size)) Self {
            const value = switch (axis) {
                .horiz => size.horiz,
                .vert => size.vert,
            };

            return .{
                .min = value,
                .max = value,
            };
        }

        pub fn fits(self: Self, vec: Vector) bool {
            if (self.min) |m| {
                if (std.simd.countTrues(vec.value < m.value) == Length) return false;
            }

            if (self.max) |m| {
                if (std.simd.countTrues(vec.value > m.value) == Length) return false;
            }

            return true;
        }
    };
}

pub fn BoxConstrains(comptime Length: usize, comptime T: type) type {
    return struct {
        const Self = @This();
        const VConstraint = VectorConstraint(Length, T);
        const _Size = Size(Length, T);

        horiz: ?VConstraint,
        vert: ?VConstraint,

        pub fn tight(size: _Size) Self {
            return .{
                .horiz = VConstraint.tight(size),
                .vert = VConstraint.tight(size),
            };
        }

        pub fn fits(self: Self, size: _Size) bool {
            if (self.horiz) |h| {
                if (!h.fits(size.horiz)) return false;
            }

            if (self.vert) |v| {
                if (!v.fits(size.vert)) return false;
            }

            return true;
        }
    };
}

test "vector constraints fittings" {
    const size = Size(2, i8){
        .horiz = vector.Vector(2, i8).init(.{ 1.0, 2.0 }),
        .vert = vector.Vector(2, i8).init(.{ 2.0, 3.0 }),
    };

    try testing.expectEqual(VectorConstraint(2, i8).tight(size, .horiz).fits(size.horiz), true);
    try testing.expectEqual(VectorConstraint(2, i8).tight(size, .horiz).fits(size.vert), false);

    try testing.expectEqual(VectorConstraint(2, i8).tight(size, .vert).fits(size.vert), true);
    try testing.expectEqual(VectorConstraint(2, i8).tight(size, .vert).fits(size.horiz), false);
}
