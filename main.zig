const std = @import("std");
const common = @import("common.zig");
const Node = @import("node.zig").Node;
const dijkstra = @import("dijkstra.zig").dijkstra;
const a_star = @import("a_star.zig").a_star;

const map_path = "maps/norden";

fn heuristic(node: *Node, target: *Node) u64 {
    const delta_lat = (node.latitude - target.latitude) * 111_195;
    // Approximate latitude for 60 degrees. cos(60deg) = 0.5
    const delta_lon = (node.longitude - target.longitude) * 55_597;
    const meters = std.math.sqrt(delta_lat * delta_lat + delta_lon * delta_lon);
    const assumed_average_speed: f64 = 25.0; // meters per second

    const heuristic_drive_time_seconds = meters / assumed_average_speed;
    return std.math.lossyCast(u64, heuristic_drive_time_seconds) * 100;
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
    try stdout.print("\n", .{});

    // Trondheim to Oslo
    // const start_node_id = 7826348;
    // const target_node_id = 2948202;

    // Create arena allocator
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    const node_parse_start_time = std.time.milliTimestamp();
    var nodes = try common.parseNodes(allocator, map_path ++ "/noder.txt");
    const node_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing nodes took {d}ms.\n", .{node_parse_end_time - node_parse_start_time});

    const connection_parse_start_time = std.time.milliTimestamp();
    try common.parseConnections(map_path ++ "/kanter.txt", &nodes);
    const connection_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing connections took {d}ms.\n\n", .{connection_parse_end_time - connection_parse_start_time});

    // Dijkstra
    try stdout.print("Running Dijkstra...\n", .{});
    const dijkstra_start_time = std.time.milliTimestamp();
    var dijkstra_map = try dijkstra(allocator, &nodes[start_node_id], &nodes[target_node_id], nodes.len);
    const dijkstra_end_time = std.time.milliTimestamp();

    const dijkstra_connection_path = try common.getPath(allocator, &dijkstra_map, target_node_id);
    std.debug.print("Path edges: {d}\n", .{dijkstra_connection_path.len});

    const dijkstra_drive_time = dijkstra_map.distance_array[target_node_id];
    var dijkstra_time_format_buffer: [100]u8 = undefined;
    const dijkstra_formatted_drive_time = try common.formatTime(&dijkstra_time_format_buffer, dijkstra_drive_time);
    try stdout.print("Drive time from {d} to {d}: {s}\n", .{ start_node_id, target_node_id, dijkstra_formatted_drive_time });
    try stdout.print("Dijkstra took: {d}ms\n\n", .{dijkstra_end_time - dijkstra_start_time});

    // A*
    try stdout.print("Running A*...\n", .{});
    const a_star_start_time = std.time.milliTimestamp();
    var a_star_map = try a_star(allocator, &nodes[start_node_id], &nodes[target_node_id], heuristic, nodes.len);
    const a_star_end_time = std.time.milliTimestamp();

    const a_star_connection_path = try common.getPath(allocator, &a_star_map, target_node_id);
    std.debug.print("Path edges: {d}\n", .{a_star_connection_path.len});

    var a_star_drive_time = a_star_map.distance_array[target_node_id];
    var a_star_time_format_buffer: [100]u8 = undefined;
    const a_star_formatted_drive_time = try common.formatTime(&a_star_time_format_buffer, a_star_drive_time);
    try stdout.print("Drive time from {d} to {d}: {s}\n", .{ start_node_id, target_node_id, a_star_formatted_drive_time });
    try stdout.print("A* took: {d}ms\n", .{a_star_end_time - a_star_start_time});
}
