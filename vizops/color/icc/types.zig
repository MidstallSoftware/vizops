const std = @import("std");
const mem = std.mem;
const enums = @import("enums.zig");
const basicTypes = @import("basic-types.zig");

pub const LutAToB = extern struct {
    sig: [4]u8 = "mAB ",
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    padding: u16 = 0,
    bCurveOffset: u32,
    matrixOffset: u32,
    mCurveOffset: u32,
    clutOffset: u32,
    aCurveOffset: u32,

    pub fn valid(self: LutAToB) bool {
        return mem.eql(u8, self.sig, "mAB ");
    }

    pub const Clut = extern struct {
        points: [16]u8,
        precision: u8,
        padding: u24 = 0,
    };
};

pub const LutBToA = extern struct {
    sig: [4]u8 = "mBA ",
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    padding: u16 = 0,
    bCurveOffset: u32,
    matrixOffset: u32,
    mCurveOffset: u32,
    clutOffset: u32,
    aCurveOffset: u32,

    pub fn valid(self: LutBToA) bool {
        return mem.eql(u8, self.sig, "mBA ");
    }

    pub const Clut = extern struct {
        points: [16]u8,
        precision: u8,
        padding: u24 = 0,
    };
};

pub const Measurement = extern struct {
    sig: [4]u8 = "meas",
    reserved: u32 = 0,
    observer: u32,
    values: basicTypes.XyzNumber,
    geom: u32,
    flare: u32,
    illum: basicTypes.Illumant,

    pub fn valid(self: Measurement) bool {
        return mem.eql(u8, self.sig, "meas");
    }
};

pub const MultiLocalizedUnicode = extern struct {
    sig: [4]u8 = "mluc",
    reserved: u32 = 0,
    count: u32,
    size: u32,

    pub fn valid(self: MultiLocalizedUnicode) bool {
        return mem.eql(u8, self.sig, "mluc");
    }

    pub const Record = extern struct {
        lang: [2]u8,
        country: [2]u8,
        len: u32,
        off: u32,
    };
};

pub const MultiProcessElements = extern struct {
    sig: [4]u8 = "mpet",
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,
    elements: u32,

    pub fn valid(self: MultiProcessElements) bool {
        return mem.eql(u8, self.sig, "mpet");
    }
};

pub const CurveSet = extern struct {
    sig: [4]u8 = "cvst",
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,

    pub fn valid(self: CurveSet) bool {
        return mem.eql(u8, self.sig, "cvst");
    }
};

pub const Matrix = extern struct {
    sig: [4]u8 = "matf",
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,

    pub fn valid(self: Matrix) bool {
        return mem.eql(u8, self.sig, "matf");
    }

    pub fn len(_: Matrix, size: usize) usize {
        return (@sizeOf(Matrix) - size) / @sizeOf(f32);
    }
};

pub const Clut = extern struct {
    sig: [4]u8 = "clut",
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,
    points: [16]u8,

    pub fn valid(self: Clut) bool {
        return mem.eql(u8, self.sig, "clut");
    }
};

pub const NamedColor2 = extern struct {
    sig: [4]u8 = "ncl2",
    reserved: u32 = 0,
    vendorFlag: [4]u8,
    count: u32,
    deviceCoords: u32,
    colorPrefix: [32]u8,
    colorSuffix: [32]u8,

    pub fn valid(self: NamedColor2) bool {
        return mem.eql(u8, self.sig, "ncl2");
    }
};

pub const ParametricCurve = extern struct {
    sig: [4]u8 = "para",
    reserved0: u32 = 0,
    type: u16,
    reserved1: u16 = 0,

    pub fn valid(self: ParametricCurve) bool {
        return mem.eql(u8, self.sig, "para");
    }
};

pub const ProfileSequenceDesc = extern struct {
    sig: [4]u8 = "pseq",
    reserved: u32 = 0,
    count: u32,

    pub fn valid(self: ProfileSequenceDesc) bool {
        return mem.eql(u8, self.sig, "pseq");
    }

    pub const Profile = extern struct {
        manufacturer: [4]u8,
        model: [4]u8,
        attribs: [8]u8,
        info: [4]u8,
    };
};

pub const ProfileSequenceIdentifier = extern struct {
    sig: [4]u8 = "psid",
    reserved: u32 = 0,
    count: u32,

    pub fn valid(self: ProfileSequenceIdentifier) bool {
        return mem.eql(u8, self.sig, "psid");
    }
};

pub const ResponseCurveSet16 = extern struct {
    sig: [4]u8 = "rcs2",
    reserved: u32 = 0,
    channels: u16,
    measurements: u16,

    pub fn valid(self: ResponseCurveSet16) bool {
        return mem.eql(u8, self.sig, "rcs2");
    }

    pub const Curve = extern struct {
        sig: [4]u8,
    };
};

pub const Signature = extern struct {
    sig: [4]u8 = "sig ",
    reserved: u32 = 0,
    value: [4]u8,

    pub fn valid(self: Signature) bool {
        return mem.eql(u8, self.sig, "sig ");
    }
};

pub const Text = extern struct {
    sig: [4]u8 = "text",
    reserved: u32 = 0,

    pub fn valid(self: Text) bool {
        return mem.eql(u8, self.sig, "text");
    }

    pub fn len(_: Text, size: usize) usize {
        return (@sizeOf(Text) - size) / @sizeOf(u8);
    }
};

pub fn Array(comptime T: type, comptime isFixed: bool) type {
    const sig = std.fmt.comptimePrint("{s}{s}{d:0>2}", .{
        @tagName(@typeInfo(T).Int.signedness)[0..1],
        if (isFixed) "f" else "i",
        @typeInfo(T).Int.bits,
    });
    return extern struct {
        const Self = @This();

        pub const Item = T;

        sig: [4]u8 = sig,
        reserved: u32,

        pub fn valid(self: Self) bool {
            return mem.eql(u8, self.sig, sig);
        }

        pub fn len(_: Self, size: usize) usize {
            return (@sizeOf(Self) - size) / @sizeOf(T);
        }
    };
}

pub const U16Fixed16Array = Array(u32, true);

pub const Uint16Array = Array(u16, false);
pub const Uint32Array = Array(u32, false);
pub const Uint64Array = Array(u64, false);
pub const Uint8Array = Array(u8, false);

pub const ViewingConditions = extern struct {
    sig: [4]u8 = "view",
    reserved: u32 = 0,
    illum: basicTypes.XyzNumber,
    surr: basicTypes.XyzNumber,
    type: enums.Illumant,

    pub fn valid(self: ViewingConditions) bool {
        return mem.eql(u8, self.sig, "view");
    }
};

pub const Xyz = extern struct {
    sig: [4]u8 = "XYZ ",
    reserved: u32 = 0,
    value: basicTypes.XyzNumber,

    pub fn valid(self: Xyz) bool {
        return mem.eql(u8, self.sig, "XYZ ");
    }
};
