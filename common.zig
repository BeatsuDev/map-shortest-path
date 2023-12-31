const std = @import("std");
const DistanceMap = @import("distance_map.zig").DistanceMap;
const Node = @import("node.zig").Node;
const Connection = @import("connection.zig").Connection;
const Landmark = @import("landmark.zig").Landmark;
const InterestPoint = @import("interest_point.zig").InterestPoint;

pub fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < s.len and s[start] == ' ' or s[start] == '\n') : (start += 1) {}
    while (end > start and s[end - 1] == ' ' or s[end - 1] == '\n') : (end -= 1) {}

    return s[start..end];
}

pub fn formatTime(buffer: []u8, hundreds_of_seconds: u32) ![]const u8 {
    const total_seconds = hundreds_of_seconds / 100;
    const hours = total_seconds / 3600;
    const minutes = (total_seconds / 60) % 60;
    const seconds = total_seconds % 60;

    var fixed_buffer_stream = std.io.fixedBufferStream(buffer);
    var buffer_writer = fixed_buffer_stream.writer();
    if (hours > 0) {
        try buffer_writer.print("{d} hours, ", .{hours});
    }

    if (minutes > 0) {
        try buffer_writer.print("{d} minutes, ", .{minutes});
    }

    try buffer_writer.print("{d} seconds", .{seconds});

    return buffer[0..fixed_buffer_stream.pos];
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

pub fn parseOppositeConnection(connections_file_path: []const u8, nodes: *[]Node) !void {
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

        const to_node_id = try std.fmt.parseInt(usize, it.next().?, 10);
        const from_node_id = try std.fmt.parseInt(usize, it.next().?, 10);
        const drive_time = try std.fmt.parseInt(u32, it.next().?, 10);
        const distance = try std.fmt.parseInt(u32, it.next().?, 10);
        const speed_limit = try std.fmt.parseInt(u16, it.next().?, 10);

        // std.debug.print("Adding connection: {d} to {d} (weight: {d})\n", .{ from_node_id, to_node_id, drive_time });

        try nodes.*[from_node_id].addConnection(&nodes.*[to_node_id], drive_time, distance, speed_limit);
    }
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

pub fn parseLandmark(allocator: std.mem.Allocator, comptime file_name: []const u8) !Landmark {
    const from_landmark_file = try std.fs.cwd().openFile(file_name ++ ".from", .{});
    const to_landmark_file = try std.fs.cwd().openFile(file_name ++ ".to", .{});

    defer from_landmark_file.close();
    defer to_landmark_file.close();

    var from_landmark_buffered_reader = std.io.bufferedReader(from_landmark_file.reader());
    var from_landmark_reader = from_landmark_buffered_reader.reader();

    var to_landmark_buffered_reader = std.io.bufferedReader(to_landmark_file.reader());
    var to_landmark_reader = to_landmark_buffered_reader.reader();

    var landmark = Landmark{
        .node_id = try from_landmark_reader.readInt(usize, .Big),
        .from = try allocator.alloc(u32, 40 * 1024 * 1024),
        .to = try allocator.alloc(u32, 40 * 1024 * 1024),
    };

    var i: usize = 0;
    while (true) : (i += 1) {
        const distance = to_landmark_reader.readInt(u32, .Big) catch {
            break;
        };
        landmark.to[i] = distance;
    }

    var j: usize = 0;
    while (true) : (j += 1) {
        const distance = to_landmark_reader.readInt(u32, .Big) catch {
            break;
        };
        landmark.from[j] = distance;
    }

    landmark.from = landmark.from[0..i];
    landmark.to = landmark.to[0..j];

    return landmark;
}

pub fn parseInterestPoints(allocator: std.mem.Allocator, file_path: []const u8) ![]InterestPoint {
    // Open file
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    // Create buffered file reader
    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    // Read first line to get interest point count
    var buffer: [256]u8 = undefined;
    const interest_point_count_string = try reader.readUntilDelimiter(&buffer, '\n');
    const interest_point_count = try std.fmt.parseInt(usize, trim(interest_point_count_string), 10);
    std.debug.print("Parsing {d} interest points.\n", .{interest_point_count});

    // Read interest points
    var interest_points = try allocator.alloc(InterestPoint, interest_point_count);
    var i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (i += 1) {
        var interest_point_data_split = std.mem.tokenizeScalar(u8, line, '\t');
        var node_id_string = interest_point_data_split.next().?;
        var interest_type_string = interest_point_data_split.next().?;
        var name = interest_point_data_split.next().?;

        interest_points[i] = InterestPoint{
            .node_id = try std.fmt.parseInt(usize, node_id_string, 10),
            .interest_type = try std.fmt.parseInt(u8, interest_type_string, 10),
            .name = try allocator.dupe(u8, name),
        };
    }

    return interest_points;
}

pub fn writeLandmark(landmark_name: []const u8, landmark: *const Landmark) !void {
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

    try from_buffered_file_writer.writeInt(usize, landmark.node_id, .Big);

    for (0..landmark.from.len) |i| {
        try from_buffered_file_writer.writeInt(u32, landmark.from[i], .Big);
    }

    const to_file = try std.fs.cwd().createFile(to_distance_file_name, .{ .read = true });
    var to_buffered_writer = std.io.bufferedWriter(to_file.writer());
    const to_buffered_file_writer = to_buffered_writer.writer();
    defer to_file.close();

    try to_buffered_file_writer.writeInt(usize, landmark.node_id, .Big);

    for (0..landmark.to.len) |i| {
        try to_buffered_file_writer.writeInt(u32, landmark.to[i], .Big);
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
