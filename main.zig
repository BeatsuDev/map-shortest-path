const std = @import("std");

const map_path = "maps/norden";

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < s.len and s[start] == ' ' or s[start] == '\n') : (start += 1) {}
    while (end > start and s[end - 1] == ' ' or s[end - 1] == '\n') : (end -= 1) {}

    return s[start..end];
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Read the nodes
    var buffer: [256]u8 = undefined;
    var file = try std.fs.cwd().openFile(map_path ++ "/noder.txt", .{});
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    var reader = buffered_reader.reader();

    const node_count_string = try reader.readUntilDelimiter(&buffer, '\n');
    const node_count = try std.fmt.parseInt(usize, trim(node_count_string), 10);

    try stdout.print("Node count: {d}\n", .{node_count});

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try stdout.print("{s}\n", .{line});
    }
}
