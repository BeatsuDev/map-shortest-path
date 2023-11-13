const std = @import("std");
const node_import = @import("node.zig");
const Connection = @import("connection.zig").Connection;
const DistanceMap = @import("distance_map.zig").DistanceMap;
const Node = node_import.Node;

const PriorityNode = struct {
    node: *Node,
    priority: u32,
};

fn comparePriorityNode(context: void, node1: PriorityNode, node2: PriorityNode) std.math.Order {
    _ = context;
    return std.math.order(node1.priority, node2.priority);
}

// Returns the shortest path of nodes from the start node to the goal node
pub fn dijkstra(allocator: std.mem.Allocator, start: *Node, node_count: usize) !DistanceMap {
    // Array to keep track of visited nodes
    var visited_nodes = try allocator.alloc(bool, node_count);
    @memset(visited_nodes, false);

    // Array of PriorityNodes with corresponding index -> node.id
    var priority_nodes = try allocator.alloc(?PriorityNode, node_count);
    @memset(priority_nodes, null);
    defer allocator.free(priority_nodes);

    var search_queue = std.PriorityQueue(PriorityNode, void, comparePriorityNode).init(allocator, {});
    var distance_map = try DistanceMap.init(allocator, start, node_count);

    try search_queue.add(PriorityNode{
        .node = start,
        .priority = 0,
    });

    while (search_queue.removeOrNull()) |priority_node| {
        try visitNode(priority_node.node, &visited_nodes, &priority_nodes, &search_queue, &distance_map);
    }

    return distance_map;
}

fn visitNode(node: *Node, visited_nodes: *[]bool, priority_nodes: *[]?PriorityNode, search_queue: *std.PriorityQueue(PriorityNode, void, comparePriorityNode), distance_map: *DistanceMap) !void {
    // Set node to visited
    visited_nodes.*[node.id] = true;

    for (node.connections.items) |*connection| {
        const new_distance = distance_map.distance_array[node.id] + connection.drive_time;

        if (visited_nodes.*[connection.to.id] == true)
            continue;

        if (new_distance < distance_map.distance_array[connection.to.id]) {
            // Update distances to neighbors
            distance_map.distance_array[connection.to.id] = new_distance;

            var old_priority_node = priority_nodes.*[connection.to.id];
            var new_priority_node = PriorityNode{
                .node = connection.to,
                .priority = new_distance,
            };
            priority_nodes.*[connection.to.id] = new_priority_node;

            // Update priority node if it was set, otherwise add it to the queue
            if (old_priority_node) |old_pn| {
                try search_queue.update(old_pn, new_priority_node);
            } else {
                try search_queue.add(new_priority_node);
            }
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

test "Priority Node comparer" {
    const allocator = std.testing.allocator;
    var node1 = Node{
        .id = 1,
        .connections = std.ArrayList(Connection).init(allocator),
        .latitude = 65.22,
        .longitude = 55.22,
    };
    var node2 = Node{
        .id = 2,
        .connections = std.ArrayList(Connection).init(allocator),
        .latitude = 25.22,
        .longitude = 15.22,
    };

    var priority1 = PriorityNode{
        .node = &node1,
        .priority = 1,
    };

    var priority2 = PriorityNode{
        .node = &node2,
        .priority = 2,
    };

    var order = comparePriorityNode({}, &priority2, &priority1);
    try std.testing.expectEqual(order, .gt);
    order = comparePriorityNode({}, &priority1, &priority2);
    try std.testing.expectEqual(order, .lt);
}
