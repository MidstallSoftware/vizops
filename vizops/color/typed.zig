pub fn Typed(comptime T: type) type {
    return struct {
        pub const sRGB = @import("types/srgb.zig").sRGB(T);
    };
}
