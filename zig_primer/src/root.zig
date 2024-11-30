const std = @import("std");
const testing = std.testing;

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    std.debug.print("Running basic add functionality test.\n", .{});
    try testing.expect(add(3, 7) == 10);
}