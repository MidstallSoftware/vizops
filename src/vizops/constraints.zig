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
            return self.min.value < vec.value and vec.value < self.max.value;
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
