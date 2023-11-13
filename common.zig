const std = @import("std");
const DistanceMap = @import("distance_map.zig").DistanceMap;
const Node = @import("node.zig").Node;
const Connection = @import("connection.zig").Connection;

pub fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < s.len and s[start] == ' ' or s[start] == '\n') : (start += 1) {}
    while (end > start and s[end - 1] == ' ' or s[end - 1] == '\n') : (end -= 1) {}

    return s[start..end];
}

pub fn parseNodes(allocator: std.mem.Allocator, nodes_file_path: []const u8) ![]Node {
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

pub fn parseConnections(connections_file_path: []const u8, nodes: *[]Node) !void {
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

pub fn writePath(file_name: []const u8, nodes: *[]Node, connections: []*const Connection) !void {
    var file = try std.fs.cwd().createFile(file_name, .{ .read = true });
    var file_writer = file.writer();
    defer file.close();

    for (connections) |conn| {
        const node = nodes.*[conn.to.id];
        try std.fmt.format(file_writer, "{d},{d}\n", .{ node.latitude, node.longitude });
    }
}
