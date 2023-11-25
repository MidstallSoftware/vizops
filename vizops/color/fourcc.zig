const builtin = @import("builtin");
const std = @import("std");
const fmt = @import("fourcc/formats.zig");

pub const Value = @import("fourcc/value.zig").Value;

pub const formats = fmt.formats;
pub const code = fmt.code;
pub const Formats = fmt.Formats;

pub const modifiers = struct {
    pub const Vendor = enum(u8) {
        none = 0,
        intel = 0x1,
        amd = 0x2,
        nvidia = 0x3,
        samsung = 0x4,
        qcom = 0x5,
        vivante = 0x6,
        broadcom = 0x7,
        arm = 0x8,
        allwinner = 0x9,
        amlogic = 0xa,

        pub inline fn decode(m: u32) Vendor {
            return @enumFromInt(@as(u8, (m >> 56) & 0xff));
        }

        pub inline fn encode(self: Vendor, val: u32) u32 {
            return (@intFromEnum(self) << 56) | (val & 0x00ffffffffffffff);
        }
    };
};

test "Check fourcc value decoded sizes" {
    const table: []const struct { u32, usize } = &.{
        .{ formats.c1, 8 },
    };

    for (table) |entry| {
        try std.testing.expectEqual(entry[1], (try Value.decode(entry[0])).width());
    }
}
