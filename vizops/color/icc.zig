const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const Icc = @This();

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
    sig: @Vector(4, u8),
    off: u32,
    size: u32,

    pub const Error = error{TooManyTags};

    pub fn readAll(alloc: Allocator, reader: anytype) (@TypeOf(reader).NoEofError || Allocator.Error || Error)!std.ArrayList(TagEntry) {
        const count = try reader.readInt(u32, .Big);
        if (count > 100) return Error.TooManyTags;

        var list = try std.ArrayList(TagEntry).initCapacity(alloc, count);
        errdefer list.deinit();

        var i: usize = 0;
        while (i < count) : (i += 1) {
            list.appendAssumeCapacity(try reader.readStructBig(TagEntry));
        }
        return list;
    }
};

pub const DateTime = extern struct {
    year: u16,
    month: u16,
    day: u16,
    hours: u16,
    minutes: u16,
    seconds: u16,
};

pub const Xyz = extern struct {
    x: i32,
    y: i32,
    z: i32,
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
    _deviceClass: @Vector(4, u8),
    colorSpace: @Vector(4, u8),
    pcs: @Vector(4, u8),
    date: DateTime,
    magic: u32,
    platform: @Vector(4, u8),
    flags: u32,
    manufacturer: u32,
    mode: u32,
    attribs: u64,
    intent: u32,
    illuminant: Xyz,
    creator: u32,
    profile: Profile,

    pub const Error = error{
        InvalidVersion,
        InvalidClass,
    };

    pub fn read(reader: anytype) (@TypeOf(reader).NoEofError || Error)!Header {
        const hdr = try reader.readStructBig(Header);

        if (hdr.version > 0x5000000) return Error.InvalidVersion;

        try reader.skipBytes(24, .{});
        _ = try hdr.deviceClass();
        return hdr;
    }

    pub fn deviceClass(self: Header) error{InvalidClass}!DeviceClass {
        var value: [4]u8 = self._deviceClass;
        inline for (@typeInfo(DeviceClass).Enum.fields) |f| {
            const decl = @field(DeviceClasses, f.name);
            if (std.mem.eql(u8, decl, &value)) return @enumFromInt(f.value);
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
tagdata: std.ArrayList([]const u8),

pub fn read(alloc: Allocator, reader: anytype) (@TypeOf(reader).NoEofError || Allocator.Error || Header.Error || TagEntry.Error)!*Icc {
    const self = try alloc.create(Icc);
    errdefer alloc.destroy(self);

    self.hdr = try Header.read(reader);
    self.tags = try TagEntry.readAll(alloc, reader);
    errdefer self.tags.deinit();

    self.tagdata = try std.ArrayList([]const u8).initCapacity(alloc, self.tags.items.len);
    errdefer self.tagdata.deinit();

    for (self.tags.items) |t| {
        var buf = try alloc.alloc(u8, t.size);
        errdefer alloc.free(buf);

        assert(try reader.read(buf) == t.size);
        self.tagdata.appendAssumeCapacity(buf);
    }
    return self;
}

pub fn deinit(self: *Icc) void {
    const alloc = self.tags.allocator;
    self.tags.deinit();

    for (self.tagdata.items) |i| alloc.free(i);
    self.tagdata.deinit();

    alloc.destroy(self);
}

test "Check size" {
    try std.testing.expectEqual(12, @sizeOf(DateTime));
    try std.testing.expectEqual(12, @sizeOf(Xyz));
    try std.testing.expectEqual(16, @sizeOf(Profile));
    try std.testing.expectEqual(100, @sizeOf(Header));
}
