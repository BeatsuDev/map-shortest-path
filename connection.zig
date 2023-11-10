const std = @import("std");
const Node = @import("node.zig").Node;

pub const Connection = struct {
    from: *Node,
    to: *Node,
    drive_time: u32,
    distance: u32,
    speed_limit: u16,
};

pub fn compareConnections(context: void, a: *const Connection, b: *const Connection) std.math.Order {
    _ = context;
    return std.math.order(a.drive_time, b.drive_time);
}
