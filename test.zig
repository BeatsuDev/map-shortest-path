const std = @import("std");

const TestType = struct {
    value: u32,
    priority: u32,
};

pub fn compareFn(context: void, test1: TestType, test2: TestType) std.math.Order {
    _ = context;
    return std.math.order(test1.priority, test2.priority);
}

const LowerPriorityTestTypeQueue = std.PriorityQueue(TestType, void, compareFn);

test "PriorityEquals" {
    const allocator = std.testing.allocator;
    var queue = LowerPriorityTestTypeQueue.init(allocator, {});
    defer queue.deinit();

    var test1 = TestType{
        .value = 10,
        .priority = 3,
    };
    var test2 = TestType{
        .value = 25,
        .priority = 3,
    };
    var new = TestType{
        .value = 25,
        .priority = 1,
    };

    try queue.add(test1);
    try queue.add(test2);

    try std.testing.expectEqual(test1, queue.peek().?);

    try queue.update(test2, new);

    try std.testing.expectEqual(new, queue.peek().?);
}
