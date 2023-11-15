const std = @import("std");
const common = @import("common.zig");
const Node = @import("node.zig").Node;
const DistanceMap = @import("distance_map.zig").DistanceMap;
const dijkstra = @import("dijkstra.zig").dijkstra;
const a_star = @import("a_star.zig").a_star;

const map_path = "maps/norden";

const Landmark = struct { node: *Node, from: []u32, to: []u32 };

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    // Parse nodes
    const node_parse_start_time = std.time.milliTimestamp();

    var nodes = try common.parseNodes(allocator, map_path ++ "/noder.txt");
    var opposite_nodes = try allocator.alloc(Node, nodes.len);
    @memcpy(opposite_nodes, nodes);

    const node_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing nodes took {d}ms.\n\n", .{node_parse_end_time - node_parse_start_time});

    // Parse connections
    const connection_parse_start_time = std.time.milliTimestamp();
    try common.parseConnections(map_path ++ "/kanter.txt", &nodes);
    const connection_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing connections took {d}ms.\n\n", .{connection_parse_end_time - connection_parse_start_time});

    // Parse opposite connecetion
    const opposite_connection_parse_start_time = std.time.milliTimestamp();
    try common.parseOppositeConnection(map_path ++ "/kanter.txt", &opposite_nodes);
    const opposite_connection_parse_end_time = std.time.milliTimestamp();
    try stdout.print("Parsing opposite connections took {d}ms.\n\n", .{opposite_connection_parse_end_time - opposite_connection_parse_start_time});

    // Find landmarks
    try stdout.print("Generating landmark distances...\n", .{});
    const start_time = std.time.milliTimestamp();
    var landmarks: [4]Landmark = undefined;
    std.debug.print("Generating distance maps for landmark 1...\n", .{});
    try createLandmark(allocator, &landmarks[0], &nodes, &opposite_nodes, 1889501);
    std.debug.print("Generating distance maps for landmark 2...\n", .{});
    try createLandmark(allocator, &landmarks[1], &nodes, &opposite_nodes, 778296);
    std.debug.print("Generating distance maps for landmark 3...\n", .{});
    try createLandmark(allocator, &landmarks[2], &nodes, &opposite_nodes, 1979543);
    std.debug.print("Generating distance maps for landmark 4...\n", .{});
    try createLandmark(allocator, &landmarks[3], &nodes, &opposite_nodes, 4285483);
    const end_time = std.time.milliTimestamp();

    for (landmarks, 0..) |landmark, i| {
        std.debug.print("Writing files for landmark {d}: {d}, {d}\n", .{ i + 1, landmark.node.latitude, landmark.node.longitude });

        var buffer: [16]u8 = undefined;
        try writeLandmark(try std.fmt.bufPrint(&buffer, "landmark_{d}", .{i}), &landmark);
    }

    try stdout.print("Preprocessing took: {d}ms\n\n", .{end_time - start_time});
}

fn createLandmark(allocator: std.mem.Allocator, landmark: *Landmark, nodes: *[]Node, opposite_nodes: *[]Node, node_id: usize) !void {
    landmark.node = &nodes.*[node_id];
    landmark.from = try allocator.alloc(u32, nodes.len);
    landmark.to = try allocator.alloc(u32, nodes.len);

    var from_landmark_node = nodes.*[node_id];
    var to_landmark_node = opposite_nodes.*[node_id];

    const distance_map = try dijkstra(allocator, &from_landmark_node, null, nodes.len);
    const opposite_distance_map = try dijkstra(allocator, &to_landmark_node, null, nodes.len);

    @memcpy(landmark.from, distance_map.distance_array);
    @memcpy(landmark.to, opposite_distance_map.distance_array);
}

fn writeLandmark(landmark_name: []const u8, landmark: *const Landmark) !void {
    const allocator = std.heap.page_allocator;

    const from_distance_file_name = try allocator.alloc(u8, landmark_name.len + 5);
    const to_distance_file_name = try allocator.alloc(u8, landmark_name.len + 3);

    defer allocator.free(from_distance_file_name);
    defer allocator.free(to_distance_file_name);

    @memcpy(from_distance_file_name[0..], landmark_name);
    @memcpy(from_distance_file_name[landmark_name.len..], ".from");

    @memcpy(to_distance_file_name[0..], landmark_name);
    @memcpy(to_distance_file_name[landmark_name.len..], ".to");

    const from_file = try std.fs.cwd().createFile(from_distance_file_name, .{ .read = true });
    var from_buffered_writer = std.io.bufferedWriter(from_file.writer());
    const from_buffered_file_writer = from_buffered_writer.writer();
    defer from_file.close();

    for (0..landmark.from.len) |i| {
        try from_buffered_file_writer.writeInt(u32, landmark.from[i], .Big);
    }

    const to_file = try std.fs.cwd().createFile(to_distance_file_name, .{ .read = true });
    var to_buffered_writer = std.io.bufferedWriter(to_file.writer());
    const to_buffered_file_writer = to_buffered_writer.writer();
    defer to_file.close();

    for (0..landmark.to.len) |i| {
        try to_buffered_file_writer.writeInt(u32, landmark.to[i], .Big);
    }
}

fn printNode(node: Node) void {
    std.debug.print("Node {d}: {d}, {d}\n", .{ node.id, node.latitude, node.longitude });
}
