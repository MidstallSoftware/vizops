const std = @import("std");
const typed = @import("color/typed.zig");

pub const icc = @import("color/icc.zig");
pub const fourcc = @import("color/fourcc.zig");
pub const types = @import("color/types.zig");
pub const Typed = typed.Typed;
pub const Union = typed.Union;

pub usingnamespace @import("color/types/srgb.zig");

pub fn readBuffer(comptime T: type, colorSpace: std.meta.DeclEnum(types), format: types.fourcc.Value, buf: []u8) !Union(T) {
    return switch (colorSpace) {
        .sRGB => .{
            .sRGB = try types.sRGB(T).readBuffer(format, buf),
        },
        else => error.InvalidColorSpace,
    };
}

pub fn readAnyBuffer(colorSpace: std.meta.DeclEnum(types), format: types.fourcc.Value, buf: []u8) !typed.Any {
    const w = format.channelSize();

    return if (format.has(.float)) switch (w) {
        16 => .{ .float16 = try readBuffer(f16, colorSpace, format, buf) },
        32 => .{ .float32 = try readBuffer(f32, colorSpace, format, buf) },
        64 => .{ .float16 = try readBuffer(f64, colorSpace, format, buf) },
        else => error.InvalidWidth,
    } else switch (w) {
        3 => .{ .uint3 = try readBuffer(u3, colorSpace, format, buf) },
        4 => .{ .uint4 = try readBuffer(u4, colorSpace, format, buf) },
        5 => .{ .uint5 = try readBuffer(u5, colorSpace, format, buf) },
        6 => .{ .uint6 = try readBuffer(u6, colorSpace, format, buf) },
        8 => .{ .uint8 = try readBuffer(u8, colorSpace, format, buf) },
        10 => .{ .uint10 = try readBuffer(u10, colorSpace, format, buf) },
        12 => .{ .uint12 = try readBuffer(u12, colorSpace, format, buf) },
        16 => .{ .uint16 = try readBuffer(u16, colorSpace, format, buf) },
        24 => .{ .uint24 = try readBuffer(u24, colorSpace, format, buf) },
        32 => .{ .uint32 = try readBuffer(u32, colorSpace, format, buf) },
        64 => .{ .uint64 = try readBuffer(u64, colorSpace, format, buf) },
        else => error.InvalidWidth,
    };
}

test {
    _ = icc;
    _ = fourcc;
    _ = types;
}
