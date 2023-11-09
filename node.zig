const std = @import("std");
const Connection = @import("connection.zig").Connection;

pub const Node = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    connections: *std.ArrayList(*Connection),

    pub fn init(allocator: std.mem.Allocator) !*Self {
        return allocator.create(Self, .{
            .allocator = allocator,
            .connections = try std.ArrayList(Self).init(allocator),
        });
    }

    pub fn addConnection(self: *Self, node: *Node, drive_time: u16, distance: u16, speed_limit: u8) !void {
        var connection = self.allocator.create(Connection);
        connection.* = Connection{
            .target = node,
            .drive_time = drive_time,
            .distance = distance,
            .speed_limit = speed_limit,
        };
        try self.connections.append(connection);
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
        for (self.connections) |connection_pointer| {
            self.allocator.destroy(connection_pointer);
        }
        self.connections.deinit();
    }
};
