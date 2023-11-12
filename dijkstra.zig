const std = @import("std");
const node_import = @import("node.zig");
const Connection = @import("connection.zig").Connection;
const Node = node_import.Node;
const PriorityNode = node_import.PriorityNode;
const comparePriorityNode = node_import.comparePriorityNode;

const DistanceMap = struct {
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

// Returns the shortest path of nodes from the start node to the goal node
pub fn dijkstra(allocator: std.mem.Allocator, start: *Node, node_count: usize) !DistanceMap {
    var visited_nodes = try allocator.alloc(bool, node_count);
    var search_queue = std.PriorityQueue(PriorityNode, void, comparePriorityNode).init(allocator, {});
    var distance_map = try DistanceMap.init(allocator, start, node_count);

    @memset(visited_nodes, false);

    try visitNode(start, &visited_nodes, &search_queue, &distance_map);

    while (search_queue.removeOrNull()) |priority_node| {
        try visitNode(priority_node.node, &visited_nodes, &search_queue, &distance_map);
    }

    return distance_map;
}

pub fn visitNode(node: *Node, visited_nodes: *[]bool, search_queue: *std.PriorityQueue(PriorityNode, void, comparePriorityNode), distance_map: *DistanceMap) !void {
    visited_nodes.*[node.id] = true;
    for (node.connections.items) |*connection| {
        const new_distance = distance_map.distance_array[node.id] + connection.drive_time;

        // std.debug.print("New distance: {d}\n", .{new_distance});

        // Add unvisited node connections to the search queue
        if (visited_nodes.*[connection.to.id] == false) {
            try search_queue.add(PriorityNode{
                // This can be changed in the future for a heuristic function
                .priority = new_distance,
                .node = connection.to,
            });
        }

        // Update distances to all adjacent nodes if new distance is smaller
        if (new_distance < distance_map.distance_array[connection.to.id]) {
            distance_map.distance_array[connection.to.id] = distance_map.distance_array[node.id] + connection.drive_time;
            distance_map.previous_connection_array[connection.to.id] = connection;

            // std.debug.print("Updating shortest path connection: {d} to {d} (new distance: {d})\n", .{ connection.from.id, connection.to.id, new_distance });
        }
    }
}

pub fn getPath(allocator: std.mem.Allocator, distance_map: *DistanceMap, target: usize) ![]*const Connection {
    var connections = std.ArrayList(*const Connection).init(allocator);

    var current_connection = distance_map.previous_connection_array[target];
    while (current_connection) |connection| {
        // std.debug.print("Current connection: {d} to {d}\n", .{ current_connection.?.from.id, current_connection.?.to.id });
        if (connection.from.id == distance_map.start.id)
            break;
        try connections.append(connection);
        current_connection = distance_map.previous_connection_array[connection.from.id];
    }

    if (current_connection) |connection| {
        try connections.append(connection);
    }

    //  std.debug.print("Path length: {d}\n", .{connections.items.len});

    return connections.items[0..];
}
