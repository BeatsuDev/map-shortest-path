const std = @import("std");
const Node = @import("node.zig").Node;
const Connection = @import("connection.zig").Connection;
const compareConnections = @import("connection.zig").compareConnections;

const DistanceMap = struct {
    start: *Node,
    previous_connection_array: []?*const Connection,
    distance_array: []u32,
};

// Returns the shortest path of nodes from the start node to the goal node
pub fn dijkstra(allocator: std.mem.Allocator, start: *Node, node_count: usize) !DistanceMap {
    var search_queue = std.PriorityQueue(*const Connection, void, compareConnections).init(allocator, {});

    var visited_array = try allocator.alloc(bool, node_count);
    var previous_connection_array = try allocator.alloc(?*const Connection, node_count);
    var distance_array = try allocator.alloc(u32, node_count);

    defer allocator.free(visited_array);
    // defer allocator.free(previous_connection_array);
    // defer allocator.free(distance_array);

    for (0..node_count) |i| {
        distance_array[i] = @as(u32, @bitCast(std.math.inf(f32)));
    }

    for (distance_array) |distance| {
        std.debug.print("{d} ", .{distance});
    }

    for (0..node_count) |i| {
        previous_connection_array[i] = null;
    }

    for (start.connections.items) |*connection| {
        try search_queue.add(connection);
        visited_array[connection.to.id] = true;

        // Update shortest path if shorter path was found
        if (distance_array[connection.from.id] + connection.distance < distance_array[connection.to.id]) {
            previous_connection_array[connection.to.id] = connection;
            distance_array[connection.to.id] = distance_array[connection.from.id] + connection.distance;
        }
    }
    distance_array[start.id] = 0;
    visited_array[start.id] = true;

    while (search_queue.removeOrNull()) |connection| {

        // Add new nodes to the search queue
        for (connection.to.connections.items) |new_connection| {
            if (visited_array[new_connection.to.id] == false) {
                visited_array[new_connection.to.id] = true;
                try search_queue.add(&new_connection);
            }

            // Update shortest path if shorter path was found
            if (distance_array[connection.from.id] + connection.distance < distance_array[connection.to.id]) {
                previous_connection_array[connection.to.id] = connection;
                distance_array[connection.to.id] = distance_array[connection.from.id] + connection.distance;
            }
        }
    }

    return DistanceMap{
        .start = start,
        .previous_connection_array = previous_connection_array,
        .distance_array = distance_array,
    };
}

pub fn getPath(allocator: std.mem.Allocator, distance_map: DistanceMap, target: usize) ![]*const Connection {
    var connections = std.ArrayList(*const Connection).init(allocator);

    var current_connection = distance_map.previous_connection_array[target];
    while (current_connection) |connection| {
        if (connection.from.id == distance_map.start.id)
            break;
        try connections.append(connection);
        current_connection = distance_map.previous_connection_array[current_connection.?.from.id];
    }

    if (current_connection) |connection| {
        try connections.append(connection);
    }

    std.debug.print("Path length: {d}\n", .{connections.items.len});

    return connections.items[0..];
}
