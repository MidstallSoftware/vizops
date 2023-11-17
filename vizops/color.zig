const std = @import("std");

pub const icc = @import("color/icc.zig");
pub const fourcc = @import("color/fourcc.zig");
pub const types = @import("color/types.zig");
pub const Typed = @import("color/typed.zig").Typed;

pub usingnamespace @import("color/types/srgb.zig");

test {
    _ = icc;
    _ = types;
}
