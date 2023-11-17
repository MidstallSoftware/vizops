pub const sRGB = @import("types/srgb.zig").sRGB;
pub const linearRGB = @import("types/linear-rgb.zig").linearRGB;
pub const hsv = @import("types/hsv.zig").Hsv;
pub const hsl = @import("types/hsl.zig").Hsl;
pub const cmyk = @import("types/cmyk.zig").Cmyk;

test {
    _ = sRGB;
}
