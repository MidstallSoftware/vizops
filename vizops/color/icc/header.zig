const enums = @import("enums.zig");
const numbers = @import("numbers.zig");
const types = @import("types.zig");

pub const Header = extern struct {
    size: u32,
    cmm: u32,
    version: u32,
    class: enums.ProfileClass,
    colorSpace: enums.ColorSpace,
    pcs: enums.ColorSpace,
    created: numbers.DateTime,
    magic: [4]u8 = "acsp",
    platform: enums.Platform,
    flags: u32,
    manufacturer: u32,
    model: u32,
    attribs: u64,
    renderingIntent: u32,
    illum: numbers.Xyz,
    creator: u32,
    id: [4]u32,
    reserved: [24]i8,
};
