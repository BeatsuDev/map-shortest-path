const Node = @import("node.zig").Node;

pub const Connection = struct {
    target: *Node,
    drive_time: u32,
    distance: u32,
    speed_limit: u8,
};
