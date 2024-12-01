const std = @import("std");

pub fn main() !u8 {
    const fileName = "input.txt";
    const allocator = std.heap.page_allocator;

    var return_value: u8 = 0;
    defer {
        if (return_value != 0) {
            std.log.err("status: {d}", .{return_value});
        } else {
            std.log.debug("status: {d}", .{return_value});
        }
    }

    const exePath = try captureArgs(allocator);

    const filePath = try buildFilePath(allocator, exePath, fileName);
    std.log.debug("File Path: {s}", .{filePath});

    const file = std.fs.openFileAbsolute(filePath, .{ .mode = .read_only }) catch |err| {
        switch (err) {
            else => {
                std.log.err("Unknown error {}", .{err});
                return_value = 1;
                return return_value;
            },
        }
    };
    defer file.close();

    // file has 2 columns. each cell is split by whitespace and each row is split by newline
    // we need to read the file line by line and put the values in a 2d array

    const reader = file.reader();
    var bufferedReader = std.io.bufferedReader(reader);
    var lineReader = bufferedReader.reader();

    var unsorted_list = std.ArrayList([2]u32).init(allocator);
    defer unsorted_list.deinit();

    // 13 chars + 1 for null terminator
    while (try lineReader.readUntilDelimiterOrEofAlloc(allocator, '\n', 14)) |line| {
        defer allocator.free(line);

        // split by three spaces
        var splitLine = std.mem.splitSequence(u8, line, "   ");

        var row: [2]u32 = [_]u32{ 0, 0 };
        var index: usize = 0;

        while (splitLine.next()) |segment| {
            if (index >= 2) {
                return error.InvalidData;
            }
            // parse the segment as a number
            const number = try std.fmt.parseInt(u32, segment, 10);
            row[index] = number;
            index += 1;
        }

        if (index != 2) {
            return error.InvalidData;
        }

        try unsorted_list.append(row);
    }

    // create left/right arrays
    var left = std.ArrayList(u32).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(u32).init(allocator);
    defer right.deinit();

    for (unsorted_list.items) |row| {
        try left.append(row[0]);
        try right.append(row[1]);
    }

    // sort left/right arrays
    std.sort.block(u32, left.items, {}, std.sort.asc(u32));
    std.sort.block(u32, right.items, {}, std.sort.asc(u32));

    // algo
    // lopp through left
    // for each element in the right that equals to the looped element in the left
    // increment the multiplier by 1
    // finally, multiply the left element by the multiplier and add it to the combined sum
    var combinedSum: u32 = 0;

    for (left.items) |leftElement| {
        var multiplier: u32 = 0;
        for (right.items) |rightElement| {
            if (leftElement == rightElement) {
                multiplier += 1;
            }
        }
        combinedSum += leftElement * multiplier;
    }

    std.log.debug("Combined Sum: {d}", .{combinedSum});

    return return_value;
}

fn absU32(a: u32, b: u32) u32 {
    if (a > b) {
        return a - b;
    } else {
        return b - a;
    }
}

fn captureArgs(allocator: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    const exePath = if (args.next()) |arg| arg else return error.InvalidArgumentCount;
    return exePath;
}

fn buildFilePath(allocator: std.mem.Allocator, exePath: []const u8, fileName: []const u8) ![]const u8 {
    const absoluteExePath = try std.fs.realpathAlloc(allocator, exePath);
    defer allocator.free(absoluteExePath);

    const exeDir = std.fs.path.dirname(absoluteExePath) orelse
        return error.InvalidPath;
    // std.log.debug("EXE DIR: {s}", .{exeDir});

    const parts1: [2][]const u8 = .{ exeDir, "../.." };
    const fileRootDir = try std.fs.path.resolve(allocator, &parts1);
    defer allocator.free(fileRootDir);
    // std.log.debug("File Root Dir: {s}", .{fileRootDir});

    const parts2: [2][]const u8 = .{ fileRootDir, fileName };
    const filePath = try std.fs.path.resolve(allocator, &parts2);
    return filePath;
}

test "simple test" {
    try std.testing.expectEqual(1, 1);
}
