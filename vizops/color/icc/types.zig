const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const Allocator = mem.Allocator;
const enums = @import("enums.zig");
const numbers = @import("numbers.zig");
const utils = @import("../../utils.zig");

pub const ChromaticityType = extern struct {
    sig: [4]u8 = .{ 'c', 'h', 'r', 'm' },
    reserved: u32 = 0,
    channels: u16,
    phosCol: u16,

    pub inline fn valid(self: ChromaticityType) bool {
        return mem.eql(u8, &self.sig, "chrm");
    }
};

pub const Cicp = extern struct {
    sig: [4]u8 = .{ 'c', 'i', 'c', 'p' },
    reserved: u32 = 0,
    colorPrimaries: u8,
    transferCharacteristics: u8,
    matrixCoefficients: u8,
    videoFullRangeFlag: u8,

    pub inline fn valid(self: Cicp) bool {
        return mem.eql(u8, &self.sig, "cicp");
    }
};

pub const ColorantOrder = extern struct {
    sig: [4]u8 = .{ 'c', 'l', 'r', 'o' },
    reserved: u32 = 0,
    count: u32,
    num: u8,

    pub inline fn valid(self: ColorantOrder) bool {
        return mem.eql(u8, &self.sig, "clro");
    }
};

pub const ColorantTable = extern struct {
    sig: [4]u8 = .{ 'c', 'l', 'r', 't' },
    reserved: u32 = 0,
    count: u32,

    pub inline fn valid(self: ColorantTable) bool {
        return mem.eql(u8, &self.sig, "clrt");
    }

    pub const Entry = extern struct {
        name: [4]u8,
        value: u16,
    };
};

pub const Curve = extern struct {
    sig: [4]u8 = .{ 'c', 'u', 'r', 'v' },
    reserved: u32 = 0,
    count: u32,

    pub inline fn valid(self: Curve) bool {
        return mem.eql(u8, &self.sig, "curv");
    }
};

pub const Data = extern struct {
    sig: [4]u8 = .{ 'd', 'a', 't', 'a' },
    reserved: u32 = 0,
    flag: enums.TypeFlag,

    pub inline fn valid(self: Data) bool {
        return mem.eql(u8, &self.sig, "data");
    }
};

pub const DateTime = extern struct {
    sig: [4]u8 = .{ 'd', 't', 'i', 'm' },
    reserved: u32 = 0,
    value: numbers.DateTime,

    pub inline fn valid(self: DateTime) bool {
        return mem.eql(u8, &self.sig, "dtim");
    }
};

pub const Dict = extern struct {
    sig: [4]u8 = .{ 'd', 'i', 'c', 't' },
    reserved: u32,
    count: u32,
    length: u32,

    pub inline fn valid(self: Dict) bool {
        return mem.eql(u8, &self.sig, "dict");
    }

    pub const Record16 = extern struct {
        nameOffset: u32,
        nameSize: u32,
        valueOffset: u32,
        valueSize: u32,
    };

    pub const Record24 = extern struct {
        nameOffset: u32,
        nameSize: u32,
        valueOffset: u32,
        valueSize: u32,

        displayNameOffset: u32,
        displayNameSize: u32,
    };

    pub const Record32 = extern struct {
        nameOffset: u32,
        nameSize: u32,
        valueOffset: u32,
        valueSize: u32,

        displayNameOffset: u32,
        displayNameSize: u32,
        displayValueOffset: u32,
        displayValueSize: u32,
    };
};

pub const Lut16 = extern struct {
    sig: [4]u8 = .{ 'm', 'f', 't', '2' },
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    pointCount: u8,
    padding: u8 = 0,
    param: [9]i32,

    pub inline fn valid(self: Lut16) bool {
        return mem.eql(u8, &self.sig, "mft2");
    }
};

pub const Lut8 = extern struct {
    sig: [4]u8 = .{ 'm', 'f', 't', '1' },
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    pointCount: u8,
    padding: u8 = 0,
    param: [9]i32,

    pub inline fn valid(self: Lut8) bool {
        return mem.eql(u8, &self.sig, "mft1");
    }
};

pub const LutAToB = extern struct {
    sig: [4]u8 = .{ 'm', 'A', 'B', ' ' },
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    padding: u16 = 0,
    bCurveOffset: u32,
    matrixOffset: u32,
    mCurveOffset: u32,
    clutOffset: u32,
    aCurveOffset: u32,

    pub inline fn valid(self: LutAToB) bool {
        return mem.eql(u8, &self.sig, "mAB ");
    }

    pub const Clut = extern struct {
        points: [16]u8,
        precision: u8,
        padding: u24 = 0,
    };
};

pub const LutBToA = extern struct {
    sig: [4]u8 = .{ 'm', 'B', 'A', ' ' },
    reserved: u32 = 0,
    inputs: u8,
    outputs: u8,
    padding: u16 = 0,
    bCurveOffset: u32,
    matrixOffset: u32,
    mCurveOffset: u32,
    clutOffset: u32,
    aCurveOffset: u32,

    pub inline fn valid(self: LutBToA) bool {
        return mem.eql(u8, &self.sig, "mBA ");
    }

    pub const Clut = extern struct {
        points: [16]u8,
        precision: u8,
        padding: u24 = 0,
    };
};

pub const Measurement = extern struct {
    sig: [4]u8 = .{ 'm', 'e', 'a', 's' },
    reserved: u32 = 0,
    observer: enums.StandardObserver,
    values: numbers.Xyz,
    geom: enums.MeasurementGeometry,
    flare: enums.MeasurementFlare,
    illum: enums.Illumant,

    pub inline fn valid(self: Measurement) bool {
        return mem.eql(u8, &self.sig, "meas");
    }
};

pub const MultiLocalizedUnicode = extern struct {
    sig: [4]u8 = .{ 'm', 'l', 'u', 'c' },
    reserved: u32 = 0,
    count: u32,
    size: u32,

    pub const HashMap = std.HashMap([4]u8, []const u16, struct {
        pub fn hash(_: @This(), s: [4]u8) u64 {
            return std.hash.Wyhash.hash(0, &s);
        }

        pub fn eql(_: @This(), a: [4]u8, b: [4]u8) bool {
            return mem.eql(u8, &a, &b);
        }
    }, std.hash_map.default_max_load_percentage);

    pub fn read(self: MultiLocalizedUnicode, alloc: Allocator, reader: anytype, _: usize) !HashMap {
        var records = try std.ArrayList(Record).initCapacity(alloc, self.count);
        defer records.deinit();

        while (records.items.len < self.count) records.appendAssumeCapacity(try utils.readStructBig(reader, Record));

        var hmap = HashMap.init(alloc);
        try hmap.ensureTotalCapacity(self.count);
        errdefer hmap.deinit();

        for (records.items) |record| {
            var key: [4]u8 = undefined;
            _ = try std.fmt.bufPrint(&key, "{s}{s}", .{ record.lang, record.country });

            var value = try alloc.alloc(u16, @divExact(record.len, @sizeOf(u16)));
            errdefer alloc.free(value);

            for (value) |*c| c.* = try reader.readInt(u16, .big);
            assert(try std.unicode.utf16CountCodepoints(value) == @divExact(record.len, @sizeOf(u16)));

            hmap.putAssumeCapacity(key, value);
        }
        return hmap;
    }

    pub inline fn valid(self: MultiLocalizedUnicode) bool {
        return mem.eql(u8, &self.sig, "mluc");
    }

    pub const Record = extern struct {
        lang: [2]u8,
        country: [2]u8,
        len: u32,
        off: u32,
    };
};

pub const MultiProcessElements = extern struct {
    sig: [4]u8 = .{ 'm', 'p', 'e', 't' },
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,
    elements: u32,

    pub inline fn valid(self: MultiProcessElements) bool {
        return mem.eql(u8, &self.sig, "mpet");
    }
};

pub const CurveSet = extern struct {
    sig: [4]u8 = .{ 'c', 'v', 's', 't' },
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,

    pub inline fn valid(self: CurveSet) bool {
        return mem.eql(u8, &self.sig, "cvst");
    }
};

pub const Matrix = extern struct {
    sig: [4]u8 = .{ 'm', 'a', 't', 'f' },
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,

    pub inline fn valid(self: Matrix) bool {
        return mem.eql(u8, &self.sig, "matf");
    }

    pub inline fn len(_: Matrix, size: usize) usize {
        return (@sizeOf(Matrix) - size) / @sizeOf(f32);
    }
};

pub const Clut = extern struct {
    sig: [4]u8 = .{ 'c', 'l', 'u', 't' },
    reserved: u32 = 0,
    inputs: u16,
    outputs: u16,
    points: [16]u8,

    pub inline fn valid(self: Clut) bool {
        return mem.eql(u8, &self.sig, "clut");
    }
};

pub const NamedColor2 = extern struct {
    sig: [4]u8 = .{ 'n', 'c', 'l', '2' },
    reserved: u32 = 0,
    vendorFlag: [4]u8,
    count: u32,
    deviceCoords: u32,
    colorPrefix: [32]u8,
    colorSuffix: [32]u8,

    pub inline fn valid(self: NamedColor2) bool {
        return mem.eql(u8, &self.sig, "ncl2");
    }
};

pub const ParametricCurve = extern struct {
    sig: [4]u8 = .{ 'p', 'a', 'r', 'a' },
    reserved0: u32 = 0,
    type: u16,
    reserved1: u16 = 0,

    pub inline fn valid(self: ParametricCurve) bool {
        return mem.eql(u8, &self.sig, "para");
    }
};

pub const ProfileSequenceDesc = extern struct {
    sig: [4]u8 = .{ 'p', 's', 'e', 'q' },
    reserved: u32 = 0,
    count: u32,

    pub inline fn valid(self: ProfileSequenceDesc) bool {
        return mem.eql(u8, &self.sig, "pseq");
    }

    pub const Profile = extern struct {
        manufacturer: [4]u8,
        model: [4]u8,
        attribs: [8]u8,
        info: [4]u8,
    };
};

pub const ProfileSequenceIdentifier = extern struct {
    sig: [4]u8 = .{ 'p', 's', 'i', 'd' },
    reserved: u32 = 0,
    count: u32,

    pub inline fn valid(self: ProfileSequenceIdentifier) bool {
        return mem.eql(u8, &self.sig, "psid");
    }
};

pub const ResponseCurveSet16 = extern struct {
    sig: [4]u8 = .{ 'r', 'c', 's', '2' },
    reserved: u32 = 0,
    channels: u16,
    measurements: u16,

    pub inline fn valid(self: ResponseCurveSet16) bool {
        return mem.eql(u8, &self.sig, "rcs2");
    }

    pub const Curve = extern struct {
        sig: [4]u8,
    };
};

pub const Signature = extern struct {
    sig: [4]u8 = .{ 's', 'i', 'g', ' ' },
    reserved: u32 = 0,
    value: [4]u8,

    pub inline fn valid(self: Signature) bool {
        return mem.eql(u8, &self.sig, "sig ");
    }
};

pub const Text = extern struct {
    sig: [4]u8 = .{ 't', 'e', 'x', 't' },
    reserved: u32 = 0,

    pub inline fn valid(self: Text) bool {
        return mem.eql(u8, &self.sig, "text");
    }

    pub inline fn len(_: Text, size: usize) usize {
        return (@sizeOf(Text) - size) / @sizeOf(u8);
    }
};

pub fn Array(comptime T: type, comptime isFixed: bool) type {
    const sig = std.fmt.comptimePrint("{s}{s}{d:0>2}", .{
        @tagName(@typeInfo(T).Int.signedness)[0..1],
        if (isFixed) "f" else "i",
        @typeInfo(T).Int.bits,
    })[0..4];
    return extern struct {
        const Self = @This();

        pub const Item = T;

        sig: [4]u8 = sig.*,
        reserved: u32,

        pub fn read(_: Self, alloc: Allocator, reader: anytype, rem: usize) !std.ArrayList(T) {
            const count = @divExact(rem, @sizeOf(T));
            var list = try std.ArrayList(T).initCapacity(alloc, count);
            errdefer list.deinit();
            while (list.items.len < count) list.appendAssumeCapacity(try reader.readInt(T, .big));
            return list;
        }

        pub inline fn valid(self: Self) bool {
            return mem.eql(u8, &self.sig, sig);
        }

        pub inline fn len(_: Self, size: usize) usize {
            return (@sizeOf(Self) - size) / @sizeOf(T);
        }
    };
}

pub const U16Fixed16Array = Array(u32, true);

pub const Uint16Array = Array(u16, false);
pub const Uint32Array = Array(u32, false);
pub const Uint64Array = Array(u64, false);
pub const Uint8Array = Array(u8, false);

pub const S16Fixed16Array = Array(i32, true);

pub const Int16Array = Array(i16, false);
pub const Int32Array = Array(i32, false);
pub const Int64Array = Array(i64, false);
pub const Int8Array = Array(i8, false);

pub const ViewingConditions = extern struct {
    sig: [4]u8 = .{ 'v', 'i', 'e', 'w' },
    reserved: u32 = 0,
    illum: numbers.Xyz,
    surr: numbers.Xyz,
    type: enums.Illumant,

    pub inline fn valid(self: ViewingConditions) bool {
        return mem.eql(u8, &self.sig, "view");
    }
};

pub const Xyz = extern struct {
    sig: [4]u8 = .{ 'X', 'Y', 'Z', ' ' },
    reserved: u32 = 0,
    value: numbers.Xyz,

    pub inline fn valid(self: Xyz) bool {
        return mem.eql(u8, &self.sig, "XYZ ");
    }
};
