const Node = @import("node.zig").Node;

pub const Connection = struct {
    target: *Node,
    drive_time: u16,
    distance: u16,
    speed_limit: u8,
};
