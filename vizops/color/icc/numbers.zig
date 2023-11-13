pub const PositionNumber = extern struct {
    off: u32,
    size: u32,
};

pub const XyzNumber = extern struct {
    x: i32,
    y: i32,
    z: i32,
};

pub const DateTimeNumber = extern struct {
    year: u16,
    month: u16,
    day: u16,
    hours: u16,
    minutes: u16,
    seconds: u16,
};
