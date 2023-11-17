pub fn Typed(comptime T: type) type {
    return struct {
        pub const sRGB = @import("types/srgb.zig").sRGB(T);
        pub const linearRGB = @import("types/linear-rgb.zig").linearRGB(T);
        pub const hsv = @import("types/hsv.zig").Hsv(T);
        pub const hsl = @import("types/hsl.zig").Hsl(T);
        pub const cmyk = @import("types/cmyk.zig").Cmyk(T);
    };
}
