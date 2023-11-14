const std = @import("std");
const mem = std.mem;
const enums = @import("enums.zig");
const numbers = @import("numbers.zig");
const types = @import("types.zig");
const utils = @import("../../utils.zig");

pub const Header = extern struct {
    size: u32,
    cmm: u32,
    version: u32,
    class: enums.ProfileClass,
    colorSpace: enums.ColorSpace,
    pcs: enums.ColorSpace,
    created: numbers.DateTime,
    magic: [4]u8 = .{ 'a', 'c', 's', 'p' },
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

    pub const Error = error{
        InvalidSize,
        InvalidMagic,
        InvalidVersion,
    };

    pub inline fn valid(self: Header) bool {
        return mem.eql(u8, self.magic, "acsp") and self.version <= 0x5000000;
    }

    pub inline fn read(reader: anytype) (@TypeOf(reader).NoEofError || Error)!Header {
        const self = try utils.readStructBig(reader, Header);
        if (self.size < @sizeOf(Header)) return Error.InvalidSize;
        if (!mem.eql(u8, &self.magic, "acsp")) return Error.InvalidMagic;
        if (self.version > 0x5000000) return Error.InvalidVersion;
        return self;
    }
};
