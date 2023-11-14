const builtin = @import("builtin");
const std = @import("std");

pub fn byteSwapAllFields(comptime S: type, ptr: *S) void {
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
            .Enum => {
                @field(ptr, f.name) = @enumFromInt(@byteSwap(@intFromEnum(@field(ptr, f.name))));
            },
            else => {
                @field(ptr, f.name) = @byteSwap(@field(ptr, f.name));
            },
        }
    }
}

pub fn readStructBig(reader: anytype, comptime T: type) @TypeOf(reader).NoEofError!T {
    var res = try reader.readStruct(T);
    if (builtin.cpu.arch.endian() != std.builtin.Endian.big) {
        byteSwapAllFields(T, &res);
    }
    return res;
}

pub fn Unicode16HashMap(comptime V: type) type {
    return std.HashMap([]const u16, V, Unicode16Context, std.hash_map.default_max_load_percentage);
}

pub const Unicode16Context = struct {
    pub fn hash(_: Unicode16Context, uc: []const u16) u64 {
        return std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(uc));
    }

    pub fn eql(_: Unicode16Context, a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
};
