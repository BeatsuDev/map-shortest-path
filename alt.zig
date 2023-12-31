const std = @import("std");
const node_import = @import("node.zig");
const Landmark = @import("landmark.zig").Landmark;
const Connection = @import("connection.zig").Connection;
const DistanceMap = @import("distance_map.zig").DistanceMap;
const Node = node_import.Node;

const PriorityNode = struct {
    node: *Node,
    priority: u64,
};

fn comparePriorityNode(context: void, node1: *PriorityNode, node2: *PriorityNode) std.math.Order {
    _ = context;
    return std.math.order(node1.priority, node2.priority);
}

// Returns the shortest path of nodes from the start node to the goal node
pub fn alt(allocator: std.mem.Allocator, start: *Node, target: *Node, comptime heuristicFn: ?fn (*Node, *Node, *[]Landmark) u64, node_count: usize, landmarks: *[]Landmark) !DistanceMap {
    var checked_nodes: usize = 1;

    // Array to keep track of visited nodes
    var visited_nodes = try allocator.alloc(bool, node_count);
    @memset(visited_nodes, false);

    // Array of PriorityNodes with corresponding index -> node.id
    // This improves runtimes for long distance by 20x or more because of the O(1)
    // lookup to see if the priority node is in the search_queue or not.
    var nodes_in_search_queue = try allocator.alloc(bool, node_count);
    @memset(nodes_in_search_queue, false);
    defer allocator.free(nodes_in_search_queue);

    var search_queue = std.PriorityQueue(*PriorityNode, void, comparePriorityNode).init(allocator, {});
    var distance_map = try DistanceMap.init(allocator, start, node_count);

    var start_priority_node = try allocator.create(PriorityNode);
    start_priority_node.* = PriorityNode{
        .node = start,
        .priority = 0,
    };
    try search_queue.add(start_priority_node);

    while (search_queue.removeOrNull()) |priority_node| {
        if (priority_node.node.id == target.id) break;
        checked_nodes += 1;
        try visitNode(allocator, priority_node.node, target, &visited_nodes, &nodes_in_search_queue, &search_queue, &distance_map, heuristicFn, landmarks);
    }

    std.debug.print("Checked {d} nodes.\n", .{checked_nodes});

    return distance_map;
}

fn visitNode(allocator: std.mem.Allocator, node: *Node, target: *Node, visited_nodes: *[]bool, nodes_in_search_queue: *[]bool, search_queue: *std.PriorityQueue(*PriorityNode, void, comparePriorityNode), distance_map: *DistanceMap, comptime heuristicFn: ?fn (*Node, *Node, *[]Landmark) u64, landmarks: *[]Landmark) !void {
    // Set node to visited
    visited_nodes.*[node.id] = true;

    for (node.connections.items) |*connection| {
        if (visited_nodes.*[connection.to.id] == true)
            continue;

        // Update distance and the priority node if this is a shorter distance
        const new_distance = distance_map.distance_array[node.id] + connection.drive_time;
        if (new_distance < distance_map.distance_array[connection.to.id]) {
            try updateDistance(allocator, new_distance, connection, target, distance_map, nodes_in_search_queue, search_queue, heuristicFn, landmarks);
        }
    }
}

fn updateDistance(allocator: std.mem.Allocator, new_distance: u32, connection: *Connection, target: *Node, distance_map: *DistanceMap, nodes_in_search_queue: *[]bool, search_queue: *std.PriorityQueue(*PriorityNode, void, comparePriorityNode), comptime heuristicFn: ?fn (*Node, *Node, *[]Landmark) u64, landmarks: *[]Landmark) !void {
    // Update distances to neighbors
    distance_map.distance_array[connection.to.id] = new_distance;
    distance_map.previous_connection_array[connection.to.id] = connection;

    if (nodes_in_search_queue.*[connection.to.id]) {
        // Updating is wrong here!!!! >:( So we have to do a linear search
        // and check the id manually instead... Maybe passing a context
        // can solve this, but for now, linear search is still very fast.
        for (0..search_queue.len) |i| {
            const priority_node = search_queue.items[i];
            if (priority_node.node.id == connection.to.id) {
                _ = search_queue.removeIndex(i);
                break;
            }
        }
        nodes_in_search_queue.*[connection.to.id] = true;
    }

    var new_priority_node = try allocator.create(PriorityNode);

    if (heuristicFn) |heuristic| {
        new_priority_node.* = PriorityNode{
            .node = connection.to,
            .priority = @as(u64, new_distance) + heuristic(connection.to, target, landmarks),
        };
    } else {
        new_priority_node.* = PriorityNode{
            .node = connection.to,
            .priority = @as(u64, new_distance),
        };
    }

    try search_queue.add(new_priority_node);
}
