const std = @import("std");
const Connection = @import("connection.zig").Connection;

pub const Node = struct {
    const Self = @This();

    id: usize,
    connections: std.ArrayList(Connection),
    latitude: f64,
    longitude: f64,

    pub fn addConnection(self: *Self, node: *Node, drive_time: u32, distance: u32, speed_limit: u16) !void {
        const connection = Connection{
            .from = self,
            .to = node,
            .drive_time = drive_time,
            .distance = distance,
            .speed_limit = speed_limit,
        };
        try self.connections.append(connection);
    }
};

pub const PriorityNode = struct {
    priority: u32,
    node: *Node,
};

pub fn comparePriorityNode(context: void, a: PriorityNode, b: PriorityNode) std.math.Order {
    _ = context;
    return std.math.order(a.priority, b.priority);
}
