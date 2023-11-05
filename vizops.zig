//!zig-autodoc-guide: README.md

const testing = @import("std").testing;

pub const constraints = @import("vizops/constraints.zig");
pub const fourcc = @import("vizops/fourcc.zig");
pub const vector = @import("vizops/vector.zig");
pub const Vector = vector.Vector;

test {
    testing.refAllDecls(@This());
}
