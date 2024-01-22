const metaplus = @import("meta+");
const std = @import("std");
const Colorspace = std.meta.DeclEnum(@import("types.zig"));

pub fn Typed(comptime T: type) type {
    return struct {
        pub const sRGB = @import("types/srgb.zig").sRGB(T);
        pub const linearRGB = @import("types/linear-rgb.zig").linearRGB(T);
        pub const hsv = @import("types/hsv.zig").Hsv(T);
        pub const hsl = @import("types/hsl.zig").Hsl(T);
        pub const cmyk = @import("types/cmyk.zig").Cmyk(T);
    };
}

pub fn Union(comptime T: type) type {
    return metaplus.unions.useTag(metaplus.unions.fromDecls(Typed(T)), std.meta.DeclEnum(Typed(T)));
}

pub fn unionEqual(comptime T: type, a: Union(T), b: Union(T)) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;

    const EnumType = @typeInfo(Union(T)).Union.tag_type.?;
    const Enum = @typeInfo(EnumType).Enum;
    inline for (@typeInfo(Union(T)).Union.fields, 0..) |field, i| {
        const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
        if (a == fieldEnum) {
            const a2 = @field(a, field.name);
            const b2 = @field(b, field.name);
            return a2.eq(b2.value);
        }
    }
    return false;
}

pub fn unionCast(comptime T: type, comptime X: type, a: Union(T)) Union(X) {
    const EnumType = @typeInfo(Union(T)).Union.tag_type.?;
    const Enum = @typeInfo(EnumType).Enum;
    inline for (@typeInfo(Union(T)).Union.fields, 0..) |field, i| {
        const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
        if (a == fieldEnum) {
            return @unionInit(Union(X), field.name, @field(a, field.name).cast(X));
        }
    }
    unreachable;
}

pub fn unionConvert(comptime T: type, colorspace: Colorspace, a: Union(T)) !Union(T) {
    const EnumType = @typeInfo(Union(T)).Union.tag_type.?;
    const Enum = @typeInfo(EnumType).Enum;
    inline for (@typeInfo(Union(T)).Union.fields, 0..) |field, i| {
        const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
        if (a == fieldEnum) {
            const a2 = @field(a, field.name);

            if (@hasDecl(@TypeOf(a2), "convert")) {
                return a2.convert(@enumFromInt(@intFromEnum(colorspace)));
            }
            return error.Incompatible;
        }
    }
    unreachable;
}

pub const Any = union(enum) {
    float16: Union(f16),
    float32: Union(f32),
    float64: Union(f64),
    uint3: Union(u3),
    uint4: Union(u4),
    uint5: Union(u5),
    uint6: Union(u6),
    uint8: Union(u8),
    uint10: Union(u10),
    uint12: Union(u12),
    uint16: Union(u16),
    uint24: Union(u24),
    uint32: Union(u32),
    uint64: Union(u64),

    pub fn Type(comptime name: []const u8) type {
        const TypeTag: std.meta.Tag(std.builtin.Type) = switch (name[0]) {
            'f' => .Float,
            'u' => .Int,
            else => @compileError("Invalid type prefix"),
        };

        const sign: std.builtin.Signedness = if (name[0] == 'u') .unsigned else .signed;

        var x: usize = 0;
        @setEvalBranchQuota(name.len * 10_000);
        inline for (name) |c| {
            if (std.ascii.isLower(c)) {
                x += 1;
            }
        }

        const size = std.fmt.parseInt(u16, name[x..], 10) catch |e| @compileError("Failed to parse size: " ++ @errorName(e));

        const InfoType = @field(std.builtin.Type, @tagName(TypeTag));
        var info: InfoType = undefined;
        info.bits = size;

        if (@hasField(InfoType, "signedness")) {
            info.signedness = sign;
        }

        return @Type(@unionInit(std.builtin.Type, @tagName(TypeTag), info));
    }

    pub inline fn getSize(self: Any) std.meta.FieldEnum(Any) {
        return std.meta.activeTag(self);
    }

    pub inline fn getColorSpace(self: Any) Colorspace {
        const EnumType = @typeInfo(Any).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Any).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const a = @field(self, field.name);
                return @enumFromInt(@intFromEnum(std.meta.activeTag(a)));
            }
        }
        unreachable;
    }

    pub fn convert(self: Any, colorspace: Colorspace) !Any {
        const EnumType = @typeInfo(Any).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Any).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const a = @field(self, field.name);
                return @unionInit(Any, field.name, try unionConvert(Type(field.name), colorspace, a));
            }
        }
        unreachable;
    }

    pub fn cast(self: Any, t: std.meta.FieldEnum(Any)) Any {
        const EnumType = @typeInfo(Any).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Any).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const a = @field(self, field.name);

                inline for (Enum.fields) |f2| {
                    if (f2.value == @intFromEnum(t)) {
                        return @unionInit(Any, f2.name, unionCast(Type(field.name), Type(f2.name), a));
                    }
                }
            }
        }
        unreachable;
    }

    pub fn matchesType(self: Any, other: Any) bool {
        if (std.meta.activeTag(self) != std.meta.activeTag(other)) return false;

        const EnumType = @typeInfo(Any).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Any).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const a = @field(self, field.name);
                const b = @field(other, field.name);

                return std.meta.activeTag(a) == std.meta.activeTag(b);
            }
        }
        return false;
    }

    pub fn equal(self: Any, other: Any) bool {
        if (std.meta.activeTag(self) != std.meta.activeTag(other)) return false;

        const EnumType = @typeInfo(Any).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Any).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const a = @field(self, field.name);
                const b = @field(other, field.name);
                return unionEqual(Type(field.name), a, b);
            }
        }
        return false;
    }
};
