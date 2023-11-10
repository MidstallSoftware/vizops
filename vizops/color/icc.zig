const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const UnicodeError = @typeInfo(@typeInfo(@TypeOf(std.unicode.utf16CountCodepoints)).Fn.return_type.?).ErrorUnion.error_set;
const Icc = @This();

fn byteSwapAllFields(comptime S: type, ptr: *S) void {
    if (@typeInfo(S) != .Struct) @compileError("byteSwapAllFields expects a struct as the first argument");
    inline for (std.meta.fields(S)) |f| {
        switch (@typeInfo(f.type)) {
            .Struct => byteSwapAllFields(f.type, &@field(ptr, f.name)),
            .Array => {
                const len = @field(ptr, f.name).len;
                var i: usize = 0;
                while (i < len) : (i += 1) {
                    @field(ptr, f.name)[i] = @byteSwap(@field(ptr, f.name)[i]);
                }
            },
            else => {
                @field(ptr, f.name) = @byteSwap(@field(ptr, f.name));
            },
        }
    }
}

fn readStructBig(reader: anytype, comptime T: type) !T {
    var res = try reader.readStruct(T);
    if (builtin.cpu.arch.endian() != std.builtin.Endian.big) {
        byteSwapAllFields(T, &res);
    }
    return res;
}

pub const DeviceClasses = struct {
    pub const input = "scnr";
    pub const display = "mntr";
    pub const output = "prtr";
    pub const link = "link";
    pub const abstract = "abst";
    pub const colorSpace = "spac";
    pub const namedColorSpace = "nmcl";
};

pub const DeviceClass = std.meta.DeclEnum(DeviceClasses);

pub const TagEntry = extern struct {
    sig: [4]u8,
    off: u32,
    size: u32,

    pub const Error = error{TooManyTags};

    pub fn readAll(alloc: Allocator, reader: anytype) (@TypeOf(reader).NoEofError || Allocator.Error || Error)!std.ArrayList(TagEntry) {
        const count = try reader.readInt(u32, .big);
        if (count > 100) return Error.TooManyTags;

        var list = try std.ArrayList(TagEntry).initCapacity(alloc, count);
        errdefer list.deinit();

        var i: usize = 0;
        while (i < count) : (i += 1) {
            list.appendAssumeCapacity(try readStructBig(reader, TagEntry));
        }
        return list;
    }
};

pub const LocaleUnicode = extern struct {
    sig: [4]u8,
    reserved: u32,
    count: u32,
    size: u32,
};

pub const LocaleUnicodeRecord = extern struct {
    lang: [2]u8,
    country: [2]u8,
    len: u32,
    off: u32,
};

pub const DateTime = extern struct {
    year: u16,
    month: u16,
    day: u16,
    hours: u16,
    minutes: u16,
    seconds: u16,
};

pub const XyzNumber = extern struct {
    x: u32,
    y: u32,
    z: u32,
};

pub const XyzType = extern struct {
    sig: [4]u8,
    reserved: u32,
};

pub const Fixed16ArrayType = extern struct {
    sig: [4]u8,
    reserved: u32,
};

pub const ChromaticityType = extern struct {
    sig: [4]u8,
    reserved: u32,
    channels: u16,
    phoscol: u16,
    c1: [2]u32,
};

pub const ParametricCurveType = extern struct {
    sig: [4]u8,
    reserved0: u32,
    type: u16,
    reserved1: u16,
};

pub const ParametricCurve = struct {
    type: u16,
    params: []i32,

    pub fn deinit(self: ParametricCurve, alloc: Allocator) void {
        alloc.free(self.params);
    }
};

pub const Chromaticity = struct {
    phoscol: u16,
    channels: []@Vector(2, u32),

    pub fn deinit(self: Chromaticity, alloc: Allocator) void {
        alloc.free(self.channels);
    }
};

pub const TagData = union(enum) {
    cprt: std.StringHashMap([]const u16),
    desc: std.StringHashMap([]const u16),
    wtpt: []@Vector(3, u32),
    rXYZ: []@Vector(3, u32),
    bXYZ: []@Vector(3, u32),
    gXYZ: []@Vector(3, u32),
    chad: []i32,
    para: ParametricCurve,
    chrm: Chromaticity,

    pub const Error = error{ UnsupportedSignature, BadSignature };

    pub fn read(alloc: Allocator, tag: TagEntry, reader: anytype) (@TypeOf(reader).NoEofError || Allocator.Error || UnicodeError || Error)!TagData {
        inline for (@typeInfo(TagData).Union.fields) |f| {
            if (std.mem.eql(u8, &tag.sig, f.name)) {
                switch (f.type) {
                    std.StringHashMap([]const u16) => {
                        const tbl = try readStructBig(reader, LocaleUnicode);
                        if (!std.mem.eql(u8, &tbl.sig, "mluc")) return error.BadSignature;

                        var reclist = try std.ArrayList(LocaleUnicodeRecord).initCapacity(alloc, tbl.count);
                        defer reclist.deinit();

                        var i: usize = 0;
                        while (i < tbl.count) : (i += 1) {
                            reclist.appendAssumeCapacity(try readStructBig(reader, LocaleUnicodeRecord));
                        }

                        var records = std.StringHashMap([]const u16).init(alloc);
                        errdefer records.deinit();
                        try records.ensureTotalCapacity(tbl.count);

                        i = 0;
                        while (i < tbl.count) : (i += 1) {
                            const record = reclist.items[i];

                            const key = try std.fmt.allocPrint(alloc, "{s}_{s}", .{ @as([2]u8, record.lang), @as([2]u8, record.country) });
                            errdefer alloc.free(key);

                            var buf = try alloc.alloc(u16, @divExact(record.len, @sizeOf(u16)));
                            errdefer alloc.free(buf);

                            for (buf) |*c| c.* = try reader.readInt(u16, .big);

                            records.putAssumeCapacity(key, buf);
                            assert(try std.unicode.utf16CountCodepoints(buf) == @divExact(record.len, @sizeOf(u16)));
                        }

                        if (std.mem.eql(u8, f.name, "cprt")) {
                            return .{ .cprt = records };
                        } else if (std.mem.eql(u8, f.name, "desc")) {
                            return .{ .desc = records };
                        }
                        unreachable;
                    },
                    []@Vector(3, u32) => {
                        const tbl = try readStructBig(reader, XyzType);
                        if (!std.mem.eql(u8, &tbl.sig, "XYZ ")) return error.BadSignature;

                        const count = @divExact(tag.size - @sizeOf(XyzType), @sizeOf(XyzNumber));
                        var list = try alloc.alloc(@Vector(3, u32), count);
                        errdefer alloc.free(list);

                        var i: usize = 0;
                        while (i < count) : (i += 1) {
                            const entry = try readStructBig(reader, XyzNumber);
                            list[i] = .{ entry.x, entry.y, entry.z };
                        }

                        if (std.mem.eql(u8, f.name, "wtpt")) {
                            return .{ .wtpt = list };
                        } else if (std.mem.eql(u8, f.name, "rXYZ")) {
                            return .{ .rXYZ = list };
                        } else if (std.mem.eql(u8, f.name, "bXYZ")) {
                            return .{ .bXYZ = list };
                        } else if (std.mem.eql(u8, f.name, "gXYZ")) {
                            return .{ .gXYZ = list };
                        }
                        unreachable;
                    },
                    []i32 => {
                        const tbl = try readStructBig(reader, Fixed16ArrayType);
                        if (!std.mem.eql(u8, &tbl.sig, "sf32")) return error.BadSignature;

                        const count = @divExact(tag.size - @sizeOf(Fixed16ArrayType), @sizeOf(i32));
                        var list = try alloc.alloc(i32, count);
                        errdefer alloc.free(list);

                        var i: usize = 0;
                        while (i < count) : (i += 1) {
                            list[i] = try reader.readInt(i32, .big);
                        }

                        if (std.mem.eql(u8, f.name, "chad")) {
                            return .{ .chad = list };
                        }
                        unreachable;
                    },
                    ParametricCurve => {
                        const tbl = try readStructBig(reader, ParametricCurveType);
                        if (!std.mem.eql(u8, &tbl.sig, "para")) return error.BadSignature;

                        const count = @divExact(tag.size - @sizeOf(ParametricCurveType), @sizeOf([2]u32));
                        std.debug.print("{}\n", .{count});
                    },
                    Chromaticity => {
                        const tbl = try readStructBig(reader, ChromaticityType);
                        if (!std.mem.eql(u8, &tbl.sig, "chrm")) return error.BadSignature;

                        const count = @divExact(tag.size - @sizeOf(ChromaticityType), @sizeOf([2]u32));
                        std.debug.print("{}\n", .{count});
                    },
                    else => @compileError("Unrecogized type: " ++ @typeName(f.type)),
                }
            }
        }
        return Error.UnsupportedSignature;
    }

    pub fn deinit(self: TagData, alloc: Allocator) void {
        switch (self) {
            .cprt, .desc => |unicode| @constCast(&unicode).deinit(),
            .wtpt, .rXYZ, .bXYZ, .gXYZ => |xyz| alloc.free(xyz),
            .chad => |sf32| alloc.free(sf32),
            .para => |para| para.deinit(alloc),
            .chrm => |chrm| chrm.deinit(alloc),
        }
    }
};

pub const Profile = extern struct {
    a: u32,
    b: u32,
    c: u32,
    d: u32,
};

// FIXME: 4 bytes too big, why?
pub const Header = extern struct {
    size: u32,
    sig: u32,
    version: u32,
    _deviceClass: [4]u8,
    colorSpace: [4]u8,
    pcs: [4]u8,
    date: DateTime,
    magic: u32,
    platform: [4]u8,
    flags: u32,
    manufacturer: u32,
    mode: u32,
    attribs: u64,
    intent: u32,
    illuminant: XyzNumber,
    creator: u32,
    profile: Profile,

    pub const Error = error{
        InvalidVersion,
        InvalidClass,
    };

    pub fn read(reader: anytype) (@TypeOf(reader).NoEofError || Error)!Header {
        const hdr = try readStructBig(reader, Header);

        if (hdr.version > 0x5000000) return Error.InvalidVersion;

        try reader.skipBytes(24, .{});
        _ = try hdr.deviceClass();
        return hdr;
    }

    pub fn deviceClass(self: Header) error{InvalidClass}!DeviceClass {
        inline for (@typeInfo(DeviceClass).Enum.fields) |f| {
            const decl = @field(DeviceClasses, f.name);
            if (std.mem.eql(u8, decl, &self._deviceClass)) return @enumFromInt(f.value);
        }
        return Error.InvalidClass;
    }

    pub fn format(self: Header, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s}{{ .deviceClass = ", .{@typeName(Header)});

        if (self.deviceClass()) |class| {
            try writer.writeAll(@tagName(class));
        } else |err| {
            try writer.writeAll(@errorName(err));
        }

        try writer.writeAll(", .size = ");
        try std.fmt.fmtIntSizeDec(self.size).format("", options, writer);

        try writer.writeAll(" }");
    }
};

hdr: Header,
tags: std.ArrayList(TagEntry),
tagdata: std.ArrayList(TagData),

pub fn read(alloc: Allocator, reader: anytype) (@TypeOf(reader).NoEofError || Allocator.Error || UnicodeError || Header.Error || TagEntry.Error || TagData.Error)!*Icc {
    const self = try alloc.create(Icc);
    errdefer alloc.destroy(self);

    self.hdr = try Header.read(reader);
    self.tags = try TagEntry.readAll(alloc, reader);
    errdefer self.tags.deinit();

    self.tagdata = std.ArrayList(TagData).init(alloc);
    errdefer self.tagdata.deinit();

    for (self.tags.items, 0..) |t, i| {
        if (t.size == 0 or t.off == 0) continue;
        if (t.size + t.off < @sizeOf(Header)) continue;

        var linked = false;
        for (self.tags.items, 0..) |t2, x| {
            if (x == i) continue;

            if (t2.off == t.off and t2.size == t.size) {
                linked = true;
                break;
            }
        }

        if (linked) continue;

        try self.tagdata.append(try TagData.read(alloc, t, reader));
    }
    return self;
}

pub fn deinit(self: *Icc) void {
    const alloc = self.tags.allocator;
    self.tags.deinit();

    for (self.tagdata.items) |i| i.deinit(alloc);
    self.tagdata.deinit();

    alloc.destroy(self);
}

test "Check size" {
    try std.testing.expectEqual(16, @sizeOf(LocaleUnicode));
    try std.testing.expectEqual(12, @sizeOf(LocaleUnicodeRecord));

    try std.testing.expectEqual(12, @sizeOf(DateTime));
    try std.testing.expectEqual(12, @sizeOf(XyzNumber));
    try std.testing.expectEqual(16, @sizeOf(Profile));
    try std.testing.expectEqual(100, @sizeOf(Header));
}
