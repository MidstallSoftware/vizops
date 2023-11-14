const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const UnicodeError = @typeInfo(@typeInfo(@TypeOf(std.unicode.utf16CountCodepoints)).Fn.return_type.?).ErrorUnion.error_set;
const utils = @import("../utils.zig");
const readStructBig = utils.readStructBig;
const UnicodeHashMap = utils.Unicode16HashMap;
const Icc = @This();

/// Enum types
pub const enums = @import("icc/enums.zig");

/// Numbered types
pub const numbers = @import("icc/numbers.zig");

/// ICC Profile Header
pub const Header = @import("icc/header.zig").Header;

/// ICC tag data
pub const tag = @import("icc/tag.zig");

/// ICC tag reader
pub const Tags = @import("icc/tags.zig");

/// Structured data types
pub const types = @import("icc/types.zig");

test "Check size" {
    try std.testing.expectEqual(128, @sizeOf(Header));
}
