const std = @import("std");

pub const Kind = enum(u3) {
    rgb,
    yuv,
    hsv,
    hsl,
    ycbcr,
    indexed,
};

pub const ChannelOrder = enum(u4) {
    none,
    rgb,
    bgr,
    rgba,
    argb,
    bgra,
    xrgba,
    xbgra,
    xrgb,
    xbgr,
};

pub const ColorSpace = enum(u2) {
    srgb,
    rec2020,
    dciP3,
};

pub const TransferFunc = enum(u2) {
    sdr,
    pq,
    hlg,
};

pub const Format = packed struct {
    kind: Kind,
    order: ChannelOrder,
    depth: u5,
    signed: u1 = 0,
    floating: u1 = 0,
    hdr: u1 = 0,
    cspace: ColorSpace = .srgb,
    tfunc: TransferFunc = .sdr,
    cll: u16 = 0,
    fall: u16 = 0,

    pub inline fn bpp(self: Format) u8 {
        return self.channels() * self.depth;
    }

    pub inline fn alpha(self: Format) bool {
        return switch (self.order) {
            .rgba, .argb, .bgra, .xrgba, .xbgra => true,
            else => false,
        };
    }

    pub inline fn channels(self: Format) u8 {
        return switch (self.order) {
            .xbgra, .xrgba => 5,
            .xrgb, .argb, .rgba, .bgra, .xbgr => 4,
            .rgb, .bgr => 3,
            .none => 1,
        };
    }

    pub inline fn encode(self: Format) u64 {
        return @bitCast(self);
    }

    pub inline fn decode(v: u64) Format {
        return @bitCast(v);
    }

    pub inline fn @"type"(comptime self: Format) type {
        return @Vector(self.channels(), if (self.floating == 1) @Type(.{
            .Float = .{
                .bits = self.depth,
            },
        }) else @Type(.{
            .Int = .{
                .signedness = if (self.signed == 1) .signed else .unsigned,
                .bits = self.depth,
            },
        }));
    }
};

test "Color format" {
    const fmt = Format{ .kind = .rgb, .order = .rgb, .depth = 8 };

    try std.testing.expectEqual(fmt.bpp(), 24);
    try std.testing.expectEqual(fmt.channels(), 3);
    try std.testing.expectEqual(fmt.type(), @Vector(3, u8));
}
