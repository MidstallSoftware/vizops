const std = @import("std");
const Allocator = std.mem.Allocator;
const utils = @import("../../utils.zig");
const Tags = @This();
const Tag = @import("tag.zig");

table: std.ArrayList(Entry),
data: std.ArrayList(Tag.Data),

pub inline fn read(alloc: Allocator, reader: anytype) !Tags {
    const count = try reader.readInt(u32, .big);

    var tbl = try std.ArrayList(Entry).initCapacity(alloc, count);
    errdefer tbl.deinit();

    while (tbl.items.len < count) tbl.appendAssumeCapacity(try Entry.read(reader));

    var data = std.ArrayList(Tag.Data).init(alloc);
    errdefer {
        for (data.items) |item| item.deinit();
        data.deinit();
    }

    for (tbl.items, 0..) |tag, i| {
        if (tag.size == 0 or tag.off == 0) continue;
        if (tag.size + tag.off < tag.off) continue;

        var skip = false;
        for (tbl.items[0..i]) |t| {
            if (t.off == tag.off and t.size == tag.size) {
                skip = true;
                break;
            }
        }

        if (skip) continue;

        try Tag.Data.read(alloc, reader, tag);
    }

    return .{
        .table = tbl,
        .data = data,
    };
}

pub inline fn deinit(self: Tags) void {
    self.table.deinit();

    for (self.data.items) |item| item.deinit();
    self.data.deinit();
}

pub fn format(self: Tags, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.writeAll(@typeName(Tags));
    try writer.writeAll("{ .table = ");
    try std.fmt.formatType(self.table.items, "any", options, writer, 2);
    try writer.writeAll(", .data = ");
    try std.fmt.formatType(self.data.items, "any", options, writer, 2);
    try writer.writeAll(" }");
}

pub const Entry = extern struct {
    sig: [4]u8,
    off: u32,
    size: u32,

    pub inline fn read(reader: anytype) @TypeOf(reader).NoEofError!Entry {
        return utils.readStructBig(reader, Entry);
    }

    pub fn format(self: Entry, comptime _: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll(@typeName(Entry));

        try writer.writeAll("{ .sig = \"");
        try std.fmt.formatType(self.sig, "s", options, writer, 1);

        try writer.writeAll("\", .off = ");
        try std.fmt.formatInt(self.off, 16, .lower, options, writer);

        try writer.writeAll(", .size = ");
        try std.fmt.fmtIntSizeBin(self.size).format("", options, writer);

        try writer.writeAll(" }");
    }
};
