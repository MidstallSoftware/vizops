const std = @import("std");
const typed = @import("color/typed.zig");

pub const icc = @import("color/icc.zig");
pub const fourcc = @import("color/fourcc.zig");
pub const types = @import("color/types.zig");
pub const Typed = typed.Typed;
pub const Union = typed.Union;
pub const Any = typed.Any;
pub const unionEqual = typed.unionEqual;

pub usingnamespace @import("color/types/srgb.zig");

pub const BlendMode = enum {
    normal,
    mul,
    screen,
    alpha,
};

pub fn blendAny(source: typed.Any, original: typed.Any, mode: BlendMode) !typed.Any {
    const fixedSource = try source.cast(original.getSize()).convert(original.getColorSpace());

    const EnumType = @typeInfo(typed.Any).Union.tag_type.?;
    const Enum = @typeInfo(EnumType).Enum;
    inline for (@typeInfo(typed.Any).Union.fields, 0..) |field, i| {
        const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
        if (fixedSource == fieldEnum) {
            const a = @field(fixedSource, field.name);
            const EnumType2 = @typeInfo(@TypeOf(a)).Union.tag_type.?;
            const Enum2 = @typeInfo(EnumType2).Enum;
            inline for (@typeInfo(@TypeOf(a)).Union.fields, 0..) |field2, x| {
                const fieldEnum2: EnumType = @enumFromInt(Enum2.fields[x].value);
                if (a == fieldEnum2) {
                    const b = @field(a, field2.name);

                    if (@hasDecl(b, "blend")) {
                        return b.blend(@field(@field(original, field.name), field2.name), mode);
                    }
                    return error.NoImplementation;
                }
            }
        }
    }
    unreachable;
}

pub fn readBuffer(comptime T: type, colorSpace: std.meta.DeclEnum(types), format: fourcc.Value, buf: []const u8) !Union(T) {
    return switch (colorSpace) {
        .sRGB => .{
            .sRGB = try types.sRGB(T).readBuffer(format, buf),
        },
        else => error.InvalidColorSpace,
    };
}

pub fn readAnyBuffer(colorSpace: std.meta.DeclEnum(types), format: fourcc.Value, buf: []const u8) !typed.Any {
    const w = format.channelSize();

    return if (format.has(.float)) switch (w) {
        16 => .{ .float16 = try readBuffer(f16, colorSpace, format, buf) },
        32 => .{ .float32 = try readBuffer(f32, colorSpace, format, buf) },
        64 => .{ .float64 = try readBuffer(f64, colorSpace, format, buf) },
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

pub fn writeBuffer(comptime T: type, format: fourcc.Value, buf: []u8, value: Union(T)) !void {
    return switch (value) {
        .sRGB => |sRGB| sRGB.writeBuffer(format, buf),
        else => error.InvalidColorSpace,
    };
}

pub fn writeAnyBuffer(format: fourcc.Value, buf: []u8, value: typed.Any) !void {
    const EnumType = @typeInfo(typed.Any).Union.tag_type.?;
    const Enum = @typeInfo(EnumType).Enum;
    inline for (@typeInfo(typed.Any).Union.fields, 0..) |field, i| {
        const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
        if (value == fieldEnum) {
            return switch (@field(value, field.name)) {
                .sRGB => |sRGB| sRGB.writeBuffer(format, buf),
                else => error.InvalidColorSpace,
            };
        }
    }
    return error.InvalidType;
}

test {
    _ = icc;
    _ = fourcc;
    _ = types;
}
