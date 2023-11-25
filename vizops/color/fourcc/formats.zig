const std = @import("std");
const builtin = @import("builtin");

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
