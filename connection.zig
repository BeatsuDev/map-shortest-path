const std = @import("std");
const Node = @import("node.zig").Node;

pub const Connection = struct {
    from: *Node,
    to: *Node,
    drive_time: u32,
    distance: u32,
    speed_limit: u16,
};
