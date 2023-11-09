const std = @import("std");
const Connection = @import("connection.zig").Connection;

pub const Node = struct {
    const Self = @This();

    id: usize,
    connections: std.ArrayList(Connection),
    latitude: f64,
    longitude: f64,

    pub fn addConnection(self: *Self, node: *Node, drive_time: u16, distance: u16, speed_limit: u8) !void {
        const connection = Connection{
            .target = node,
            .drive_time = drive_time,
            .distance = distance,
            .speed_limit = speed_limit,
        };
        try self.connections.append(connection);
    }
};
