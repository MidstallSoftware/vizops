pub fn Channel(comptime Parent: type, comptime T: type, comptime Index: type) type {
    return struct {
        const Self = @This();

        parent: *const Parent,
        index: Index,
        data: ?T = null,

        pub inline fn value(self: Self) T {
            return self.data orelse self.parent.value[@intFromEnum(self.index)];
        }

        pub inline fn set(self: *Self, v: T) *Self {
            self.data = v;
            return self;
        }

        pub inline fn add(self: *Self, v: T) *Self {
            return self.set(self.value() + v);
        }

        pub inline fn sub(self: *Self, v: T) *Self {
            return self.set(self.value() - v);
        }

        pub inline fn mul(self: *Self, v: T) *Self {
            return self.set(self.value() * v);
        }

        pub inline fn div(self: *Self, v: T) *Self {
            return self.set(self.value() / v);
        }

        pub inline fn done(self: *Self) Parent {
            var vec = self.parent.value;
            vec[@intFromEnum(self.index)] = self.value();
            return .{
                .value = vec,
            };
        }
    };
}
