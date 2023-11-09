const std = @import("std");

pub const Kind = enum(u4) {
    xyz,
    xyY,
    lab,
    lch,
    jch,
    rgb,
};

pub const Format = packed struct {
    kind: Kind,
    depth: u5,
    floating: u1 = 1,
};
