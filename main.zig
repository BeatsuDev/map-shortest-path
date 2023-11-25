const std = @import("std");
const common = @import("common.zig");
const Node = @import("node.zig").Node;
const Landmark = @import("landmark.zig").Landmark;
const dijkstra = @import("dijkstra.zig").dijkstra;
const find_nearest_interest_points = @import("find_nearest_interest_points.zig").find_nearest_interest_points;
const a_star = @import("a_star.zig").a_star;
const alt = @import("alt.zig").alt;

const map_path = "maps/island";

fn heuristic(node: *Node, target: *Node) u64 {
    const delta_lat = (node.latitude - target.latitude) * 111_195;
    // Approximate latitude for 60 degrees. cos(60deg) = 0.5
    const delta_lon = (node.longitude - target.longitude) * 55_597;
    const meters = std.math.sqrt(delta_lat * delta_lat + delta_lon * delta_lon);
    const assumed_average_speed: f64 = 25.0; // meters per second

    const heuristic_drive_time_seconds = meters / assumed_average_speed;
    return std.math.lossyCast(u64, heuristic_drive_time_seconds) * 100;
}

fn alt_heuristic(node: *Node, target: *Node, landmarks: *[]Landmark) u64 {
    var best_estimate: u32 = 0;

    for (landmarks.*) |*landmark| {
        var estimate1: u32 = @max(landmark.from[target.id] - landmark.from[node.id], 0);
        var estimate2: u32 = @max(landmark.to[node.id] - landmark.to[target.id], 0);

        var local_best: u32 = @max(estimate1, estimate2);
        if (local_best > best_estimate) {
            best_estimate = local_best;
        }
    }

    return @as(u64, best_estimate);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    // const stdin = std.io.getStdIn().reader();

    // var buffer: [30]u8 = undefined;
    // try stdout.print("Start node ID: ", .{});
    // const start_node_string = buffer[0..try stdin.read(&buffer)];
    // const start_node_id = try std.fmt.parseInt(usize, common.trim(start_node_string), 10);

    // try stdout.print("End node ID: ", .{});
    // const target_node_string = buffer[0..try stdin.read(&buffer)];
    // const target_node_id = try std.fmt.parseInt(usize, common.trim(target_node_string), 10);
    // try stdout.print("\n", .{});

    // Reykjavik to Bakkagerði
    const start_node_id = 104736;
    const target_node_id = 106158;

    // Create arena allocator
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    const node_parse_start_time = std.time.milliTimestamp();
    var nodes = try common.parseNodes(allocator, map_path ++ "/noder.txt");
    const node_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing nodes took {d}ms.\n\n", .{node_parse_end_time - node_parse_start_time});

    const connection_parse_start_time = std.time.milliTimestamp();
    try common.parseConnections(map_path ++ "/kanter.txt", &nodes);
    const connection_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing connections took {d}ms.\n\n", .{connection_parse_end_time - connection_parse_start_time});

    const interest_point_start_time = std.time.milliTimestamp();
    const interest_points = try common.parseInterestPoints(allocator, map_path ++ "/interessepkt.txt");
    _ = interest_points;
    const interest_point_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing interest points took {d}ms.\n\n", .{interest_point_end_time - interest_point_start_time});

    // Dijkstra
    try stdout.print("Running Dijkstra...\n", .{});
    const dijkstra_start_time = std.time.milliTimestamp();
    var dijkstra_map = try dijkstra(allocator, &nodes[start_node_id], &nodes[target_node_id], nodes.len);
    const dijkstra_end_time = std.time.milliTimestamp();

    const dijkstra_connection_path = try common.getPath(allocator, &dijkstra_map, target_node_id);
    std.debug.print("Path edges: {d}\n", .{dijkstra_connection_path.len});
    try common.writePath("path.txt", &nodes, dijkstra_connection_path);

    const dijkstra_drive_time = dijkstra_map.distance_array[target_node_id];
    var dijkstra_time_format_buffer: [100]u8 = undefined;
    const dijkstra_formatted_drive_time = try common.formatTime(&dijkstra_time_format_buffer, dijkstra_drive_time);
    try stdout.print("Drive time from {d} to {d}: {s}\n", .{ start_node_id, target_node_id, dijkstra_formatted_drive_time });
    try stdout.print("Dijkstra took: {d}ms\n\n", .{dijkstra_end_time - dijkstra_start_time});

    // Finding nearest interest points
    // try stdout.print("Finding nearest interest points...\n", .{});
    // const trondheim_camping = 3005466;
    // const start_time = std.time.milliTimestamp();
    // var drinking_places = try find_nearest_interest_points(allocator, &nodes[trondheim_camping], 16, nodes.len, interest_points, 5);
    // const end_time = std.time.milliTimestamp();

    // for (drinking_places) |drinking_place| {
    //     try stdout.print("Found drinking place: {s} ({d}, {d})\n", .{
    //         drinking_place.name,
    //         nodes[drinking_place.node_id].latitude,
    //         nodes[drinking_place.node_id].longitude,
    //     });
    // }
    // try stdout.print("Found interest points in {d}ms\n\n", .{end_time - start_time});

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
    try stdout.print("A* took: {d}ms\n\n", .{a_star_end_time - a_star_start_time});

    // ALT
    try stdout.print("Running ALT...\n(NOT IMPLEMENTED YET)\n", .{});

    // Load ALT Landmarks
    const landmark0 = try common.parseLandmark(allocator, "landmark_0");
    const landmark1 = try common.parseLandmark(allocator, "landmark_1");
    const landmark2 = try common.parseLandmark(allocator, "landmark_2");
    const landmark3 = try common.parseLandmark(allocator, "landmark_3");

    var landmarks = try allocator.alloc(Landmark, 4);
    landmarks[0] = landmark0;
    landmarks[1] = landmark1;
    landmarks[2] = landmark2;
    landmarks[3] = landmark3;

    // Print the node IDs of each landmark
    try stdout.print("Landmark 0: {d}\n", .{landmark0.node_id});
    try stdout.print("Landmark 1: {d}\n", .{landmark1.node_id});
    try stdout.print("Landmark 2: {d}\n", .{landmark2.node_id});
    try stdout.print("Landmark 3: {d}\n", .{landmark3.node_id});

    const alt_start_time = std.time.milliTimestamp();
    var alt_map = try alt(allocator, &nodes[start_node_id], &nodes[target_node_id], alt_heuristic, nodes.len, &landmarks);
    const alt_end_time = std.time.milliTimestamp();

    var alt_drive_time = alt_map.distance_array[target_node_id];
    var alt_time_format_buffer: [100]u8 = undefined;
    const alt_formatted_drive_time = try common.formatTime(&alt_time_format_buffer, alt_drive_time);
    try stdout.print("Drive time from {d} to {d}: {s}\n", .{ start_node_id, target_node_id, alt_formatted_drive_time });
    try stdout.print("ALT took: {d}ms\n", .{alt_end_time - alt_start_time});
}
