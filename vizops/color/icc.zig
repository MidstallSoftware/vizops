const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const UnicodeError = @typeInfo(@typeInfo(@TypeOf(std.unicode.utf16CountCodepoints)).Fn.return_type.?).ErrorUnion.error_set;
const utils = @import("../utils.zig");
const readStructBig = utils.readStructBig;
const UnicodeHashMap = utils.Unicode16HashMap;
const Icc = @This();

pub const enums = @import("icc/enums.zig");
pub const numbers = @import("icc/numbers.zig");
pub const Header = @import("icc/header.zig").Header;
pub const types = @import("icc/types.zig");

test "Check size" {
    try std.testing.expectEqual(128, @sizeOf(Header));
}
