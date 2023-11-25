const std = @import("std");
const builtin = @import("builtin");
const colorTypes = @import("../typed.zig");
const ColorTypedUnion = colorTypes.Union;
const ColorTypedAny = colorTypes.Any;

pub const Value = union(enum) {
    c: u8,
    d: u8,
    r: u8,
    rg: @Vector(2, u8),
    gr: @Vector(2, u8),
    rgb: @Vector(3, u8),
    bgr: @Vector(3, u8),
    xrgb: @Vector(4, u8),
    xbgr: @Vector(4, u8),
    rgba: @Vector(4, u8),
    rgbx: @Vector(4, u8),
    bgrx: @Vector(4, u8),
    argb: @Vector(4, u8),
    abgr: @Vector(4, u8),
    bgra: @Vector(4, u8),
    argb_f: @Vector(4, u8),
    abgr_f: @Vector(4, u8),
    xrgb_f: @Vector(4, u8),
    xbgr_f: @Vector(4, u8),
    xrgb_a: @Vector(4, u8),
    xbgr_a: @Vector(4, u8),
    rgbx_a: @Vector(4, u8),
    bgrx_a: @Vector(4, u8),
    axbxgxrx: @Vector(8, u8),

    pub const Feature = enum {
        float,
        plane,
        padding,
    };

    pub fn channelSize(self: Value) usize {
        const EnumType = @typeInfo(Value).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const fieldType = @TypeOf(@field(self, field.name));
                if (fieldType == u8) return @field(self, field.name);

                var size: usize = 0;
                inline for (field.name, 0..) |c, x| {
                    if (c == '_') break;

                    if (c != 'x') {
                        size = @max(size, @field(self, field.name)[x]);
                    }
                }
                return size;
            }
        }
        return 0;
    }

    pub inline fn paddingSize(self: Value) usize {
        const EnumType = @typeInfo(Value).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                const fieldType = @TypeOf(@field(self, field.name));
                if (fieldType == u8) return 0;

                var size: usize = 0;
                inline for (field.name, 0..) |c, x| {
                    if (c == '_') break;

                    if (c == 'x') {
                        size += @field(self, field.name)[x];
                    }
                }
                return size;
            }
        }
        return 0;
    }

    pub inline fn channelCount(self: Value) usize {
        const EnumType = @typeInfo(Value).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                return field.name.len - std.mem.count(u8, field.name, "_");
            }
        }
        return 0;
    }

    pub inline fn paddingCount(self: Value) usize {
        const EnumType = @typeInfo(Value).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                return std.mem.count(u8, field.name, "x");
            }
        }
        return 0;
    }

    pub inline fn has(self: Value, feat: Feature) bool {
        const EnumType = @typeInfo(Value).Union.tag_type.?;
        const Enum = @typeInfo(EnumType).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: EnumType = @enumFromInt(Enum.fields[i].value);
            if (self == fieldEnum) {
                return switch (feat) {
                    .float => std.mem.endsWith(u8, field.name, "_f"),
                    .plane => std.mem.endsWith(u8, field.name, "_a"),
                    .padding => std.mem.count(u8, field.name, "x") > 0,
                };
            }
        }
        return false;
    }

    inline fn decodePaddedRgbTuple(i: u8) @Vector(4, u8) {
        const x: u8 = i / 3;
        if ((i % 4) == 0) {
            return @splat(x);
        }

        var result: @Vector(4, u8) = .{ 0, x, x, x };
        while (result[0] == 0 or (@reduce(.Add, result) % 2) != 0) : (result[0] += 1) {}
        return result;
    }

    pub fn decode(ivalue: u32) (std.fmt.ParseIntError || error{InvalidFormat})!Value {
        var value: [4]u8 = undefined;
        std.mem.writeInt(u32, &value, ivalue, builtin.cpu.arch.endian());
        const whitespaceCount = std.mem.count(u8, &value, " ");

        if ((value[0] == 'C' or value[0] == 'D' or value[0] == 'R') and whitespaceCount > 0) {
            const end = std.mem.indexOf(u8, &value, " ") orelse @panic("indexOf() looking for whitespace failed when whitespace count is greater than zero.");
            const i = try std.fmt.parseInt(u8, value[1..][0..(end - 1)], 10);

            return switch (value[0]) {
                'C' => .{ .c = i },
                'D' => .{ .d = i },
                'R' => .{ .r = i },
                else => unreachable,
            };
        }

        const chCount = blk: {
            var i: usize = 0;
            for (value) |c| {
                if (std.ascii.isUpper(c)) i += 1;
            }
            break :blk i;
        };

        const numCount = blk: {
            var i: usize = 0;
            for (value) |c| {
                if (std.ascii.isDigit(c)) i += 1;
            }
            break :blk i;
        };

        if (chCount == 2 and numCount == 2) {
            return switch (value[0]) {
                'R' => switch (value[1]) {
                    'G' => blk: {
                        const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);
                        const a = i / 10;
                        const b = i % 10;

                        if (a == b) {
                            break :blk .{
                                .rg = .{ a, b },
                            };
                        }

                        if (i == 32) {
                            break :blk .{
                                .rg = @splat(i / 2),
                            };
                        }

                        if (i == 16) {
                            break :blk .{
                                .rgb = .{ 5, 6, 5 },
                            };
                        }

                        break :blk .{
                            .rgb = @splat(i / 3),
                        };
                    },
                    'X' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);
                            break :blk .{ .rgbx = std.simd.reverseOrder(decodePaddedRgbTuple(i)) };
                        }

                        if (value[2] == 'A' and std.ascii.isDigit(value[3])) {
                            const i = value[3] - '0';
                            break :blk .{ .rgbx_a = @splat(i) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'A' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .rgba = std.simd.reverseOrder(decodePaddedRgbTuple(i)) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'B' => switch (value[1]) {
                    'A' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .bgra = std.simd.reverseOrder(decodePaddedRgbTuple(i)) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'G' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk switch (i) {
                                16 => .{ .bgr = .{ 5, 6, 5 } },
                                24 => .{ .bgr = @splat(8) },
                                else => error.InvalidFormat,
                            };
                        }

                        if (value[2] == 'R' and std.ascii.isDigit(value[3])) {
                            const i = value[3] - '0';

                            if (i == 8) {
                                break :blk .{ .bgr = .{ 2, 3, 3 } };
                            }
                            break :blk error.InvalidFormat;
                        }
                        break :blk error.InvalidFormat;
                    },
                    'X' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .bgrx = std.simd.reverseOrder(decodePaddedRgbTuple(i)) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'G' => switch (value[1]) {
                    'R' => blk: {
                        const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);
                        const a = i / 10;
                        const b = i % 10;

                        if (a == b) {
                            break :blk .{
                                .gr = .{ a, b },
                            };
                        }

                        break :blk .{
                            .gr = @splat(i / 2),
                        };
                    },
                    else => error.InvalidFormat,
                },
                'A' => switch (value[1]) {
                    'R' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .argb = decodePaddedRgbTuple(i) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'B' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            if (i == 10) {
                                break :blk .{ .axbxgxrx = .{ 10, 6, 10, 6, 10, 6, 10, 6 } };
                            }

                            break :blk .{ .abgr = decodePaddedRgbTuple(i) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'X' => switch (value[1]) {
                    'R' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .xrgb = decodePaddedRgbTuple(i) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'B' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk .{ .xbgr = decodePaddedRgbTuple(i) };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                else => error.InvalidFormat,
            };
        }

        if (chCount == 3 and numCount == 1) {
            return switch (value[0]) {
                'R' => switch (value[1]) {
                    'G' => switch (value[2]) {
                        'B' => blk: {
                            const i = try std.fmt.parseInt(u8, value[3..][0..1], 10);

                            if (i == 8) {
                                break :blk .{
                                    .rgb = .{ 3, 3, 2 },
                                };
                            }
                            break :blk error.InvalidFormat;
                        },
                        else => error.InvalidFormat,
                    },
                    'X' => switch (value[2]) {
                        'A' => blk: {
                            const i = value[3] - '0';
                            break :blk .{ .rgbx_a = @splat(i) };
                        },
                        else => error.InvalidFormat,
                    },
                    else => error.InvalidFormat,
                },
                'B' => switch (value[1]) {
                    'G' => switch (value[2]) {
                        'R' => blk: {
                            const i = try std.fmt.parseInt(u8, value[3..][0..1], 10);

                            if (i == 8) {
                                break :blk .{
                                    .bgr = .{ 2, 3, 3 },
                                };
                            }
                            break :blk error.InvalidFormat;
                        },
                        else => error.InvalidFormat,
                    },
                    'X' => switch (value[2]) {
                        'A' => blk: {
                            const i = value[3] - '0';
                            break :blk .{ .bgrx_a = @splat(i) };
                        },
                        else => error.InvalidFormat,
                    },
                    else => error.InvalidFormat,
                },
                'X' => switch (value[1]) {
                    'R', 'B' => blk: {
                        if (std.ascii.isDigit(value[2]) and value[3] == 'H') {
                            const i: @Vector(4, u8) = @splat(64 / (value[2] - '0'));
                            break :blk switch (value[1]) {
                                'R' => .{ .xrgb_f = i },
                                'B' => .{ .xbgr_f = i },
                                else => error.InvalidFormat,
                            };
                        }

                        if (value[2] == 'A' and std.ascii.isDigit(value[3])) {
                            const i: @Vector(4, u8) = @splat(64 / (value[3] - '0'));
                            break :blk switch (value[1]) {
                                'R' => .{ .xrgb_a = i },
                                'B' => .{ .xbgr_a = i },
                                else => error.InvalidFormat,
                            };
                        }
                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'A' => switch (value[1]) {
                    'R', 'B' => blk: {
                        if (std.ascii.isDigit(value[2]) and value[3] == 'H') {
                            const i: @Vector(4, u8) = @splat(64 / (value[2] - '0'));
                            break :blk switch (value[1]) {
                                'R' => .{ .argb_f = i },
                                'B' => .{ .abgr_f = i },
                                else => error.InvalidFormat,
                            };
                        }
                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                else => error.InvalidFormat,
            };
        }
        return error.InvalidFormat;
    }

    pub inline fn width(self: Value) usize {
        return switch (self) {
            .c, .d => 8,
            .r => |v| if (v > 8) 16 else 8,
            .rg, .gr => |v| @reduce(.Add, v),
            .rgb, .bgr => |v| @reduce(.Add, v),
            .abgr_f, .argb_f, .xbgr_f, .xrgb_f, .rgba, .xrgb, .rgbx, .bgrx, .xbgr, .argb, .abgr, .bgra => |v| @reduce(.Add, v),
            .xrgb_a, .xbgr_a, .rgbx_a, .bgrx_a => |v| @reduce(.Add, v) + 8,
            .axbxgxrx => |v| @reduce(.Add, v),
        };
    }

    pub inline fn @"for"(self: Value, comptime T: type) !ColorTypedUnion(T) {
        return switch (self) {
            .r, .rg, .gr, .rgb, .bgr, .rgba, .xrgb, .rgbx, .bgrx, .xbgr, .argb, .abgr, .bgra, .axbxgxrx, .xrgb_a, .xbgr_a, .rgbx_a, .bgrx_a => if (@typeInfo(T) != .Int) error.InvalidType else .{
                .sRGB = .{},
            },
            .abgr_f, .argb_f, .xbgr_f, .xrgb_f => if (@typeInfo(T) != .Float) error.InvalidType else .{
                .sRGB = .{},
            },
            else => error.InvalidType,
        };
    }

    pub fn forAny(self: Value) !ColorTypedAny {
        const w = self.channelSize();

        return if (self.has(.float)) switch (w) {
            16 => .{ .float16 = try self.@"for"(f16) },
            32 => .{ .float32 = try self.@"for"(f32) },
            64 => .{ .float64 = try self.@"for"(f64) },
            else => error.InvalidWidth,
        } else switch (w) {
            3 => .{ .uint3 = try self.@"for"(u3) },
            4 => .{ .uint4 = try self.@"for"(u4) },
            5 => .{ .uint5 = try self.@"for"(u5) },
            6 => .{ .uint6 = try self.@"for"(u6) },
            8 => .{ .uint8 = try self.@"for"(u8) },
            10 => .{ .uint10 = try self.@"for"(u10) },
            12 => .{ .uint12 = try self.@"for"(u12) },
            16 => .{ .uint16 = try self.@"for"(u16) },
            24 => .{ .uint24 = try self.@"for"(u24) },
            32 => .{ .uint32 = try self.@"for"(u32) },
            64 => .{ .uint64 = try self.@"for"(u64) },
            else => error.InvalidWidth,
        };
    }
};
