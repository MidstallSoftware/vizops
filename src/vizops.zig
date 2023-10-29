const testing = @import("std").testing;

pub const constraints = @import("vizops/constraints.zig");
pub const vector = @import("vizops/vector.zig");
pub const Vector = vector.Vector;

test {
    testing.refAllDecls(@This());
}
