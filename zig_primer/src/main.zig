const std = @import("std");

pub fn main() !void {
    const print = std.log.info;
    print("Hello, {s}!", .{"world"});

    const x: i32 = 1;
    const pointer: *const i32 = &x;
    print("1 = {}, {}\n", .{ x, pointer.* });
    print("1 = {}", .{pointer.*});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    std.debug.print("list length: {d}\n", .{list.items.len});
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "learn" {
    const mat4x4 = [4][4]f32{
        [_]f32{ 1.0, 0.0, 0.0, 0.0 },
        [_]f32{ 0.0, 1.0, 0.0, 0.0 },
        [_]f32{ 0.0, 0.0, 1.0, 0.0 },
        [_]f32{ 0.0, 0.0, 0.0, 1.0 },
    };

    for (mat4x4, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            std.debug.print("mat4x4[{d}][{d}] = {d:.1}\n", .{ i, j, cell });
        }
    }

    try std.testing.expect(mat4x4[1][1] == 1.0);
}
