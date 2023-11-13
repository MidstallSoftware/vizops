pub const Illumant = enum(u8) { unknown = 0, d50 = 0x1, d65 = 0x2, d93 = 0x3, f2 = 0x4, d55 = 0x5, a = 0x6, eqiPowE = 0x7, f8 = 0x8 };

pub const DataTypeFlag = enum(u32) {
    ascii = 0,
    binary = 1,
};
