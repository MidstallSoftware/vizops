pub const StandardObserver = enum(u32) {
    unknown = 0,
    cie1931 = 1,
    cie1964 = 2,
};

pub const Illumant = enum(u32) { unknown = 0, d50 = 0x1, d65 = 0x2, d93 = 0x3, f2 = 0x4, d55 = 0x5, a = 0x6, eqiPowE = 0x7, f8 = 0x8 };

pub const MeasurementGeometry = enum(u32) {
    unknown = 0,
    @"45" = 1,
    @"0" = 2,
};

pub const MeasurementFlare = enum(u32) {
    @"0" = 0,
    @"100" = 1000,
};

pub const TypeFlag = enum(u32) {
    ascii = 0,
    binary = 1,
};

pub const ProfileClass = enum(u32) {
    input = 0x73636E72,
    display = 0x6D6E7472,
    outputs = 0x70727472,
    deviceLink = 0x6C696E6B,
    colorSpace = 0x73706163,
    abstract = 0x61627374,
    namedColor = 0x6E6D636C,
};

pub const ColorSpace = enum(u32) {
    xyz = 0x58595A20,
    lab = 0x4C616220,
    luv = 0x4C757620,
    ycbcr = 0x59436272,
    yxy = 0x59787920,
    rgb = 0x52474220,
    gray = 0x47524159,
    hsv = 0x48535620,
    hls = 0x484C5320,
    cmyk = 0x434D594B,
    cmy = 0x434D5920,
    color2 = 0x32434C52,
    color3 = 0x33434C52,
    color4 = 0x34434C52,
    color5 = 0x35434C52,
    color6 = 0x36434C52,
    color7 = 0x37434C52,
    color8 = 0x38434C52,
    color9 = 0x39434C52,
    color10 = 0x41434C52,
    color11 = 0x42434C52,
    color12 = 0x43434C52,
    color13 = 0x44434C52,
    color14 = 0x45434C52,
    color15 = 0x46434C52,
};

pub const Platform = enum(u32) {
    apple = 0x4150504C,
    microsoft = 0x4D534654,
    solaris = 0x53554E57,
    sgi = 0x53474920,
    taligent = 0x54474E54,
    unix = 0x2A6E6978,
};
