const std = @import("std");
const Node = @import("node.zig").Node;
const Connection = @import("connection.zig").Connection;

pub const DistanceMap = struct {
    allocator: std.mem.Allocator,
    start: *Node,
    previous_connection_array: []?*const Connection,
    distance_array: []u32,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, start: *Node, node_count: usize) !Self {
        var distance_map = try allocator.create(Self);
        distance_map.* = Self{
            .allocator = allocator,
            .start = start,
            .previous_connection_array = try allocator.alloc(?*const Connection, node_count),
            .distance_array = try allocator.alloc(u32, node_count),
        };
        @memset(distance_map.distance_array, std.math.maxInt(u32));
        @memset(distance_map.previous_connection_array, null);
        distance_map.distance_array[start.id] = 0;
        return distance_map.*;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.distance_array);
        self.allocator.free(self.distance_array);
        self.allocator.destroy(self);
    }
};
