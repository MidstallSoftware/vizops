const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const mem = std.mem;
const numbers = @import("numbers.zig");
const types = @import("types.zig");
const Tags = @import("tags.zig");
const utils = @import("../../utils.zig");

pub const AToB = union(enum) {
    lut8: types.Lut8,
    lut16: types.Lut16,
    a2b: types.LutAToB,
};

pub const Trc = union(enum) { curve: types.Curve, param: types.ParametricCurve };

pub const BToA = union(enum) {
    lut8: types.Lut8,
    lut16: types.Lut16,
    b2a: types.LutBToA,
};

pub const Data = union(enum) {
    A2B0: AToB,
    A2B1: AToB,
    bXYZ: numbers.Xyz,
    bTRC: Trc,
    rTRC: Trc,
    B2A0: BToA,
    B2A1: BToA,
    B2A2: BToA,
    calt: types.DateTime,
    chrm: types.Chromaticity.Value,
    cprt: types.MultiLocalizedUnicode.Value,
    dmnd: types.MultiLocalizedUnicode.Value,
    dmdd: types.MultiLocalizedUnicode.Value,
    desc: types.MultiLocalizedUnicode.Value,
    rXYZ: numbers.Xyz,
    gXYZ: numbers.Xyz,
    meta: types.Dict.Value,
    wtpt: numbers.Xyz,
    chad: std.ArrayList(i32),

    pub const Error = error{
        InvalidSignature,
        InvalidField,
    };

    pub fn read(alloc: Allocator, reader: anytype, entry: Tags.Entry) !Data {
        var sig: [4]u8 = undefined;
        assert(try reader.read(&sig) == @sizeOf(@TypeOf(sig)));

        inline for (@typeInfo(types).Struct.decls) |decl| {
            const field = @field(types, decl.name);
            const fieldType = @TypeOf(field);
            if (fieldType != type) continue;

            const expectedSig: *const [4]u8 = @ptrCast(@alignCast(@typeInfo(field).Struct.fields[0].default_value));
            if (mem.eql(u8, expectedSig, &sig)) {
                var tbl: [1]field = undefined;
                tbl[0].sig = sig;
                try reader.readNoEof(mem.sliceAsBytes(tbl[0..])[4..]);

                if (builtin.target.cpu.arch.endian() != std.builtin.Endian.big) {
                    utils.byteSwapAllFields(field, &tbl[0]);
                }

                assert(tbl[0].valid());

                inline for (@typeInfo(field).Struct.fields) |f| {
                    const check: bool = comptime mem.startsWith(u8, f.name, "reserved");
                    if (check) {
                        assert(@field(tbl[0], f.name) == 0);
                    }
                }

                const rem = entry.size - @sizeOf(field);
                const ValueType = if (@hasDecl(field, "read")) @typeInfo(@typeInfo(@TypeOf(field.read)).Fn.return_type.?).ErrorUnion.payload else field;
                const value: ValueType = if (@hasDecl(field, "read")) try tbl[0].read(alloc, reader, rem) else tbl[0];

                if (!@hasDecl(field, "read")) {
                    // TODO: uncomment when everything is implemented
                    // assert(rem == 0);
                    try reader.skipBytes(rem, .{});
                }

                @setEvalBranchQuota(1_000_000);
                inline for (@typeInfo(Data).Union.fields) |f| {
                    switch (@typeInfo(f.type)) {
                        .Union => |u| {
                            inline for (u.fields) |f2| {
                                if (f2.type == ValueType) {
                                    const expectedSig2: *const [4]u8 = @ptrCast(@alignCast(@typeInfo(f2.type).Struct.fields[0].default_value));
                                    if (mem.eql(u8, expectedSig, expectedSig2)) {
                                        return @unionInit(Data, f.name, @unionInit(f.type, f2.name, value));
                                    }
                                }
                            }
                        },
                        .Struct => {
                            if (ValueType == f.type) {
                                if (mem.eql(u8, f.name, &entry.sig)) {
                                    return @unionInit(Data, f.name, value);
                                }
                            }
                        },
                        else => |t| @compileError("Incompatible type: " ++ @tagName(t)),
                    }
                }

                std.debug.print("{s}\n", .{entry.sig});
                return error.InvalidField;
            }
        }

        return error.InvalidSignature;
    }

    pub inline fn format(self: Data, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        inline for (@typeInfo(Data).Union.fields) |f| {
            if (mem.eql(u8, f.name, std.enums.tagName(std.meta.Tag(Data), std.meta.activeTag(self)).?)) {
                const field = @field(self, f.name);
                switch (f.type) {
                    types.Dict.Value => {
                        try writer.writeAll(@typeName(types.Dict));
                        try writer.writeByte('{');

                        var iter = field.iterator();
                        var i: usize = 0;
                        while (iter.next()) |entry| : (i += 1) {
                            if (i + 1 < field.count()) try writer.writeByte(',');
                            try writer.print(" .{} = \"{}\"", .{
                                std.unicode.fmtUtf16le(entry.key_ptr.*),
                                std.unicode.fmtUtf16le(entry.value_ptr.*),
                            });
                        }

                        try writer.writeAll(" }");
                    },
                    types.MultiLocalizedUnicode.Value => {
                        try writer.writeAll(@typeName(types.MultiLocalizedUnicode));
                        try writer.writeByte('{');

                        var iter = field.iterator();
                        var i: usize = 0;
                        while (iter.next()) |entry| : (i += 1) {
                            if (i + 1 < field.count()) try writer.writeByte(',');
                            try writer.print(" .{s} = \"{}\"", .{
                                entry.key_ptr.*,
                                std.unicode.fmtUtf16le(entry.value_ptr.*),
                            });
                        }

                        try writer.writeAll(" }");
                    },
                    else => return std.fmt.formatType(field, fmt, options, writer, 3),
                }
            }
        }
    }

    pub inline fn deinit(self: Data, alloc: Allocator) void {
        inline for (@typeInfo(Data).Union.fields) |f| {
            if (mem.eql(u8, f.name, std.enums.tagName(std.meta.Tag(Data), std.meta.activeTag(self)).?)) {
                const field = @constCast(&@field(self, f.name));
                switch (f.type) {
                    types.Chromaticity.Value => field.deinit(alloc),
                    types.Dict.Value => field.deinit(),
                    types.MultiLocalizedUnicode.Value => field.deinit(),
                    std.ArrayList(i32) => field.deinit(),
                    else => {},
                }
            }
        }
    }
};
