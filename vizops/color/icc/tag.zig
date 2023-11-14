const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const mem = std.mem;
const types = @import("types.zig");
const Tags = @import("tags.zig");
const utils = @import("../../utils.zig");

pub const AToB0 = union(enum) {
    lut8: types.Lut8,
    lut16: types.Lut16,
    a2b: types.LutAToB,
};

pub const AToB2 = union(enum) {
    lut8: types.Lut8,
    lut16: types.Lut16,
    a2b: types.LutAToB,
};

pub const Data = union(enum) {
    a2b0: AToB0,
    a2b2: AToB2,
    bXYZ: types.Xyz,

    pub const Error = error{
        InvalidSignature,
    };

    pub fn read(alloc: Allocator, reader: anytype, entry: Tags.Entry) !void {
        var sig: [4]u8 = undefined;
        assert(try reader.read(&sig) == @sizeOf(@TypeOf(sig)));

        var self: Data = undefined;
        _ = self;
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

                // TODO: uncomment when everything is implemented
                //if (!@hasDecl(field, "read")) assert(rem == 0);

                std.debug.print("{}\n", .{value});
                return;
            }
        }

        return error.InvalidSignature;
    }

    pub inline fn deinit(self: Data) void {
        _ = self;
    }
};
