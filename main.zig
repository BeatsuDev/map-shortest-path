const std = @import("std");
const dijkstra = @import("dijkstra.zig").dijkstra;
const getPath = @import("dijkstra.zig").getPath;
const Node = @import("node.zig").Node;
const Connection = @import("connection.zig").Connection;

const map_path = "maps/island";
const start_node_id = 4000;
const target_node_id = 5000;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Create arena allocator
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena_allocator.allocator();
    defer arena_allocator.deinit();

    var nodes = try parseNodes(allocator, map_path ++ "/noder.txt");
    try parseConnections(map_path ++ "/kanter.txt", &nodes);
    try stdout.print("Node {d} connections: {d}\n", .{ start_node_id, nodes[start_node_id].connections.items.len });

    var distance_map = try dijkstra(allocator, &nodes[start_node_id], nodes.len);
    const connection_path = try getPath(allocator, &distance_map, target_node_id);
    try writePath("path.txt", connection_path);
    std.debug.print("Path length: {d}\n", .{connection_path.len});
    try stdout.print("Drive time from {d} to {d}: {d}\n", .{ start_node_id, target_node_id, distance_map.distance_array[target_node_id] / 100 });
}

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < s.len and s[start] == ' ' or s[start] == '\n') : (start += 1) {}
    while (end > start and s[end - 1] == ' ' or s[end - 1] == '\n') : (end -= 1) {}

    return s[start..end];
}

fn parseNodes(allocator: std.mem.Allocator, nodes_file_path: []const u8) ![]Node {
    // Open file
    var file = try std.fs.cwd().openFile(nodes_file_path, .{});
    defer file.close();

    // Create buffered file reader
    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    // Read first line to get node count
    var buffer: [64]u8 = undefined;
    const node_count_string = try reader.readUntilDelimiter(&buffer, '\n');
    const node_count = try std.fmt.parseInt(usize, trim(node_count_string), 10);
    std.debug.print("Parsing {d} nodes.\n", .{node_count});

    // Read nodes
    var nodes = try allocator.alloc(Node, node_count);
    var i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (i += 1) {
        var node_split_data = std.mem.tokenizeScalar(u8, line, ' ');
        var node_id_string = node_split_data.next().?;
        var node_latitude_string = node_split_data.next().?;
        var node_longitude_string = node_split_data.next().?;

        nodes[i] = Node{
            .id = try std.fmt.parseInt(usize, node_id_string, 10),
            .connections = std.ArrayList(Connection).init(allocator),
            .latitude = try std.fmt.parseFloat(f64, node_latitude_string),
            .longitude = try std.fmt.parseFloat(f64, node_longitude_string),
        };
    }

    return nodes;
}

fn parseConnections(connections_file_path: []const u8, nodes: *[]Node) !void {
    // Open file
    var file = try std.fs.cwd().openFile(connections_file_path, .{});
    defer file.close();

    // Create buffered file reader
    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    // Read first line to get connections count
    var buffer: [128]u8 = undefined;
    const connection_count_string = try reader.readUntilDelimiter(&buffer, '\n');
    const connection_count = try std.fmt.parseInt(usize, trim(connection_count_string), 10);
    std.debug.print("Parsing {d} connections.\n", .{connection_count});

    // Read connections
    var i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (i += 1) {
        var it = std.mem.tokenizeScalar(u8, trim(line), '\t');

        const from_node_id = try std.fmt.parseInt(usize, it.next().?, 10);
        const to_node_id = try std.fmt.parseInt(usize, it.next().?, 10);
        const drive_time = try std.fmt.parseInt(u32, it.next().?, 10);
        const distance = try std.fmt.parseInt(u32, it.next().?, 10);
        const speed_limit = try std.fmt.parseInt(u16, it.next().?, 10);

        // std.debug.print("Adding connection: {d} to {d} (weight: {d})\n", .{ from_node_id, to_node_id, drive_time });

        try nodes.*[from_node_id].addConnection(&nodes.*[to_node_id], drive_time, distance, speed_limit);
    }
}

fn writePath(file_name: []const u8, connections: []*const Connection) !void {
    var file = try std.fs.cwd().createFile(file_name, .{ .read = true });
    var file_writer = file.writer();
    defer file.close();

    for (connections) |conn| {
        try std.fmt.format(file_writer, "{d}\n", .{conn.to.id});
    }
}
