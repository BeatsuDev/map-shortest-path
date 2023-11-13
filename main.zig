const std = @import("std");
const common = @import("common.zig");
const Node = @import("node.zig").Node;
const a_star = @import("a_star.zig").a_star;

const map_path = "maps/norden";

fn heuristic(node_distance: u32, node: *Node, target: *Node) u64 {
    const delta_lat = (node.latitude - target.latitude);
    const delta_lon = (node.longitude - target.longitude);
    const factor: f64 = 100 * (delta_lat * delta_lat) + (delta_lon * delta_lon);

    const heuristic_value = std.math.lossyCast(u64, factor * @as(f64, @floatFromInt(node_distance)));

    // std.debug.print("Factor: {d}\n", .{heuristic_value});
    return heuristic_value;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var buffer: [30]u8 = undefined;
    try stdout.print("Start node ID: ", .{});
    const start_node_string = buffer[0..try stdin.read(&buffer)];
    const start_node_id = try std.fmt.parseInt(usize, common.trim(start_node_string), 10);

    try stdout.print("End node ID: ", .{});
    const target_node_string = buffer[0..try stdin.read(&buffer)];
    const target_node_id = try std.fmt.parseInt(usize, common.trim(target_node_string), 10);

    // Trondheim to Oslo
    // const start_node_id = 7826348;
    // const target_node_id = 2948202;

    // Create arena allocator
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    var nodes = try common.parseNodes(allocator, map_path ++ "/noder.txt");
    try common.parseConnections(map_path ++ "/kanter.txt", &nodes);
    try stdout.print("Node {d} connections: {d}\n", .{ start_node_id, nodes[start_node_id].connections.items.len });

    var distance_map = try a_star(allocator, &nodes[start_node_id], &nodes[target_node_id], heuristic, nodes.len);
    const connection_path = try common.getPath(allocator, &distance_map, target_node_id);
    try common.writePath("path.txt", &nodes, connection_path);
    std.debug.print("Path edges: {d}\n", .{connection_path.len});

    var time = distance_map.distance_array[target_node_id];
    try stdout.print("Drive time from {d} to {d}: {d}\n", .{ start_node_id, target_node_id, time });
}
