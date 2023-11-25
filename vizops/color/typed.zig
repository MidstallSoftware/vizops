const metaplus = @import("meta+");
const std = @import("std");

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

pub const Any = union(enum) {
    float32: Union(f32),
    float64: Union(f64),
    uint8: Union(u8),
    uint16: Union(u16),
    uint24: Union(u24),
    uint32: Union(u32),
    uint64: Union(u64),
};
