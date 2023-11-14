const std = @import("std");
const node_import = @import("node.zig");
const Connection = @import("connection.zig").Connection;
const DistanceMap = @import("distance_map.zig").DistanceMap;
const Node = node_import.Node;

const PriorityNode = struct {
    node: *Node,
    priority: u64,
};

fn comparePriorityNode(context: void, node1: PriorityNode, node2: PriorityNode) std.math.Order {
    _ = context;
    return std.math.order(node1.priority, node2.priority);
}

// Returns the shortest path of nodes from the start node to the goal node
pub fn dijkstra(allocator: std.mem.Allocator, start: *Node, target: ?*Node, node_count: usize) !DistanceMap {
    var checked_nodes: usize = 1;

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
        if (target) |target_node| {
            if (priority_node.node.id == target_node.id) break;
        }
        checked_nodes += 1;
        try visitNode(priority_node.node, &visited_nodes, &priority_nodes, &search_queue, &distance_map);
    }

    std.debug.print("Checked {d} nodes.\n", .{checked_nodes});
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
            try updateDistance(new_distance, connection, distance_map, priority_nodes, search_queue);
        }
    }
}

fn updateDistance(new_distance: u32, connection: *Connection, distance_map: *DistanceMap, priority_nodes: *[]?PriorityNode, search_queue: *std.PriorityQueue(PriorityNode, void, comparePriorityNode)) !void {
    // Update distances to neighbors
    distance_map.distance_array[connection.to.id] = new_distance;
    distance_map.previous_connection_array[connection.to.id] = connection;

    var old_priority_node = priority_nodes.*[connection.to.id];
    var new_priority_node = PriorityNode{
        .node = connection.to,
        .priority = new_distance,
    };
    priority_nodes.*[connection.to.id] = new_priority_node;

    // Update priority node if it was set, otherwise add it to the queue
    if (old_priority_node) |old_pn| {
        // Updating is wrong here!!!! >:( So we have to do a linear search
        // and check the id manually instead... Maybe passing a context
        // can solve this, but for now, linear search is still very fast.
        // try search_queue.update(old_pn, new_priority_node);
        for (search_queue.items, 0..) |priority_node, i| {
            if (priority_node.node.id == old_pn.node.id) {
                _ = search_queue.removeIndex(i);
                break;
            }
        }
        try search_queue.add(new_priority_node);
    } else {
        try search_queue.add(new_priority_node);
    }
}
