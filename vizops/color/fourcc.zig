const builtin = @import("builtin");
const std = @import("std");

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

    pub const Feature = enum {
        float,
        plane,
    };

    pub inline fn has(self: Value, feat: Feature) bool {
        const Enum = @typeInfo(@typeInfo(Value).Union.tag_type.?).Enum;
        inline for (@typeInfo(Value).Union.fields, 0..) |field, i| {
            const fieldEnum: Enum = @enumFromInt(Enum.fields[i].value);
            if (std.meta.activeTag(self) == fieldEnum) {
                return switch (feat) {
                    .float => std.mem.endsWith(u8, field.name, "_f"),
                    .plane => std.mem.endsWith(u8, field.name, "_a"),
                };
            }
        }
        return false;
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

                            break :blk switch (i) {
                                12 => .{ .rgbx = @splat(4) },
                                15 => .{ .rgbx = .{ 5, 5, 5, 1 } },
                                24 => .{ .rgbx = @splat(8) },
                                30 => .{ .rgbx = .{ 10, 10, 10, 2 } },
                                else => error.InvalidFormat,
                            };
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

                            break :blk switch (i) {
                                12 => .{ .rgba = @splat(4) },
                                15 => .{ .rgba = .{ 5, 5, 5, 1 } },
                                24 => .{ .rgba = @splat(8) },
                                30 => .{ .rgba = .{ 10, 10, 10, 2 } },
                                else => error.InvalidFormat,
                            };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'B' => switch (value[1]) {
                    'A' => blk: {
                        if (std.ascii.isDigit(value[2])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk switch (i) {
                                12 => .{ .bgra = @splat(4) },
                                15 => .{ .bgra = .{ 5, 5, 5, 1 } },
                                24 => .{ .bgra = @splat(8) },
                                30 => .{ .bgra = .{ 10, 10, 10, 2 } },
                                else => error.InvalidFormat,
                            };
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

                            break :blk switch (i) {
                                12 => .{ .bgrx = @splat(4) },
                                15 => .{ .bgrx = .{ 5, 5, 5, 1 } },
                                24 => .{ .bgrx = @splat(8) },
                                30 => .{ .bgrx = .{ 10, 10, 10, 2 } },
                                else => error.InvalidFormat,
                            };
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

                            break :blk switch (i) {
                                12 => .{ .argb = @splat(4) },
                                15 => .{ .argb = .{ 1, 5, 5, 5 } },
                                24 => .{ .argb = @splat(8) },
                                30 => .{ .argb = .{ 2, 10, 10, 10 } },
                                48 => .{ .argb = @splat(16) },
                                else => error.InvalidFormat,
                            };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'B' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk switch (i) {
                                12 => .{ .abgr = @splat(4) },
                                15 => .{ .abgr = .{ 1, 5, 5, 5 } },
                                24 => .{ .abgr = @splat(8) },
                                30 => .{ .abgr = .{ 2, 10, 10, 10 } },
                                48 => .{ .abgr = @splat(16) },
                                else => error.InvalidFormat,
                            };
                        }

                        break :blk error.InvalidFormat;
                    },
                    else => error.InvalidFormat,
                },
                'X' => switch (value[1]) {
                    'R' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk switch (i) {
                                12 => .{ .xrgb = @splat(4) },
                                15 => .{ .xrgb = .{ 1, 5, 5, 5 } },
                                24 => .{ .xrgb = @splat(8) },
                                30 => .{ .xrgb = .{ 2, 10, 10, 10 } },
                                48 => .{ .xrgb = @splat(16) },
                                else => error.InvalidFormat,
                            };
                        }

                        break :blk error.InvalidFormat;
                    },
                    'B' => blk: {
                        if (std.ascii.isDigit(value[3])) {
                            const i = try std.fmt.parseInt(u8, value[2..][0..2], 10);

                            break :blk switch (i) {
                                12 => .{ .xbgr = @splat(4) },
                                15 => .{ .xbgr = .{ 1, 5, 5, 5 } },
                                24 => .{ .xbgr = @splat(8) },
                                30 => .{ .xbgr = .{ 2, 10, 10, 10 } },
                                48 => .{ .xbgr = @splat(16) },
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
        };
    }
};

pub inline fn code(s: *const [4:0]u8) u32 {
    return std.mem.readInt(u32, s, builtin.cpu.arch.endian());
}

pub const formats = struct {
    pub const c1 = code("C1  ");
    pub const c2 = code("C2  ");
    pub const c4 = code("C4  ");
    pub const c8 = code("C8  ");

    pub const d1 = code("D1  ");
    pub const d2 = code("D2  ");
    pub const d4 = code("D4  ");
    pub const d8 = code("D8  ");

    pub const r1 = code("R1  ");
    pub const r2 = code("R2  ");
    pub const r4 = code("R4  ");
    pub const r8 = code("R8  ");
    pub const r10 = code("R10 ");
    pub const r12 = code("R12 ");
    pub const r16 = code("R16 ");

    pub const rg88 = code("RG88");
    pub const gr88 = code("GR88");

    pub const rg1616 = code("RG32");
    pub const gr1616 = code("GR32");

    pub const rgb332 = code("RGB8");
    pub const bgr233 = code("BGR8");

    pub const xrgb4444 = code("XR12");
    pub const xbgr4444 = code("XB12");
    pub const rgbx4444 = code("RX12");
    pub const bgrx4444 = code("BX12");

    pub const argb4444 = code("AR12");
    pub const abgr4444 = code("AB12");
    pub const rgba4444 = code("RA12");
    pub const bgra4444 = code("BA12");

    pub const xrgb1555 = code("XR15");
    pub const xbgr1555 = code("XB15");
    pub const rgbx5551 = code("RX15");
    pub const bgrx5551 = code("BX15");

    pub const argb1555 = code("AR15");
    pub const abgr1555 = code("AB15");
    pub const rgba5551 = code("RA15");
    pub const bgra5551 = code("BA15");

    pub const rgb565 = code("RG16");
    pub const bgr565 = code("BG16");

    pub const rgb888 = code("RG24");
    pub const bgr888 = code("BG24");

    pub const xrgb8888 = code("XR24");
    pub const xbgr8888 = code("XB24");
    pub const rgbx8888 = code("RX24");
    pub const bgrx8888 = code("BX24");

    pub const argb8888 = code("AR24");
    pub const abgr8888 = code("AB24");
    pub const rgba8888 = code("AR24");
    pub const bgra8888 = code("BA24");

    pub const xrgb2101010 = code("XR30");
    pub const xbgr2101010 = code("XB30");
    pub const rgbx1010102 = code("RX30");
    pub const bgrx1010102 = code("BX30");

    pub const argb2101010 = code("AR30");
    pub const abgr2101010 = code("AB30");
    pub const rgba1010102 = code("RA30");
    pub const bgra1010102 = code("BA30");

    pub const xrgb16161616 = code("XR48");
    pub const xbgr16161616 = code("XB48");

    pub const argb16161616 = code("AR48");
    pub const abgr16161616 = code("AB48");
    pub const xrgb16161616f = code("XR4H");
    pub const xbgr16161616f = code("XB4H");

    pub const argb16161616f = code("AR4H");
    pub const abgr16161616f = code("AB4H");

    pub const axbxgxrx106106106106 = code("AB10");

    pub const yuyv = code("YUYV");
    pub const yvyu = code("YVYU");
    pub const uyvy = code("UYVY");
    pub const vyuy = code("VYUY");

    pub const ayuv = code("AYUV");
    pub const avuy8888 = code("AVUY");
    pub const xyuv8888 = code("XYUV");
    pub const xvuy8888 = code("XVUY");
    pub const vuy888 = code("VU24");
    pub const vuy101010 = code("VU30");

    pub const y210 = code("Y210");
    pub const y212 = code("Y212");
    pub const y216 = code("Y216");

    pub const y410 = code("Y410");
    pub const y412 = code("Y412");
    pub const y416 = code("Y416");

    pub const xvyu2101010 = code("XV30");
    pub const xvyu12_16161616 = code("XV36");
    pub const xvyu16161616 = code("XV48");

    pub const y0l0 = code("Y0L0");
    pub const x0l0 = code("X0L0");

    pub const y0l2 = code("Y0L2");
    pub const x0l2 = code("X0L2");

    pub const yuv420_8bit = code("YU08");
    pub const yuv420_10bit = code("YU10");

    pub const xrgb8888_a8 = code("XRA8");
    pub const xbgr8888_a8 = code("XBA8");
    pub const rgbx8888_a8 = code("RXA8");
    pub const bgrx8888_a8 = code("BXA8");
    pub const rgb888_a8 = code("R8A8");
    pub const bgr888_a8 = code("B8A8");
    pub const rgb565_a8 = code("R5A8");
    pub const bgr565_a8 = code("B5A8");

    pub const nv12 = code("NV12");
    pub const nv21 = code("NV21");
    pub const nv16 = code("NV16");
    pub const nv61 = code("NV61");
    pub const nv24 = code("NV24");
    pub const nv42 = code("NV42");

    pub const nv15 = code("NV15");
    pub const nv20 = code("NV20");
    pub const nv30 = code("NV30");

    pub const p210 = code("P210");
    pub const p010 = code("P010");
    pub const p012 = code("P012");
    pub const p016 = code("P016");
    pub const p030 = code("P030");
    pub const q410 = code("Q410");

    pub const q401 = code("Q401");

    pub const yuv410 = code("YUV9");
    pub const yvu410 = code("YVU9");
    pub const yuv411 = code("YU11");
    pub const yvu411 = code("YV11");
    pub const yuv420 = code("YU12");
    pub const yvu420 = code("YV12");
    pub const yuv422 = code("YU16");
    pub const yvu422 = code("YV16");
    pub const yuv444 = code("YU24");
    pub const yvu444 = code("YV24");
};

pub const Format = std.meta.DeclEnum(formats);

pub const modifiers = struct {
    pub const Vendor = enum(u8) {
        none = 0,
        intel = 0x1,
        amd = 0x2,
        nvidia = 0x3,
        samsung = 0x4,
        qcom = 0x5,
        vivante = 0x6,
        broadcom = 0x7,
        arm = 0x8,
        allwinner = 0x9,
        amlogic = 0xa,

        pub inline fn decode(m: u32) Vendor {
            return @enumFromInt(@as(u8, (m >> 56) & 0xff));
        }

        pub inline fn encode(self: Vendor, val: u32) u32 {
            return (@intFromEnum(self) << 56) | (val & 0x00ffffffffffffff);
        }
    };
};

test "Check fourcc value decoded sizes" {
    const table: []const struct { u32, usize } = &.{
        .{ formats.c1, 8 },
    };

    for (table) |entry| {
        try std.testing.expectEqual(entry[1], (try Value.decode(entry[0])).width());
    }
}