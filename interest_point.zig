pub const InterestPoint = struct {
    node_id: usize,
    interest_type: u8,
    name: []const u8,

    const Self = @This();

    pub fn isPlaceName(self: Self) void {
        return (self.interest_type & 1) == 1;
    }

    pub fn isGasStation(self: Self) void {
        return (self.interest_type & 2) == 2;
    }

    pub fn isChargingStation(self: Self) void {
        return (self.interest_type & 4) == 4;
    }

    pub fn isDiningPlace(self: Self) void {
        return (self.interest_type & 8) == 8;
    }

    pub fn isDrinkingPlace(self: Self) void {
        return (self.interest_type & 16) == 16;
    }

    pub fn isSleepingPlace(self: Self) void {
        return (self.interest_type & 32) == 32;
    }
};
