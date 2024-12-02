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

    // var unsorted_list = std.ArrayList([]u32).init(allocator);
    // defer unsorted_list.deinit();

    // guesstimate of 50 bytes per line
    var validSequences: u32 = 0;
    while (try lineReader.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |line| {
        defer allocator.free(line);

        // split by three spaces
        var splitLine = std.mem.splitScalar(u8, line, ' ');
        var segmentArray = std.ArrayList(u32).init(allocator);
        defer segmentArray.deinit();

        while (splitLine.next()) |segment| {
            const number = try std.fmt.parseInt(u32, segment, 10);
            _ = try segmentArray.append(number);
        }

        // now we have a row of numbers
        // check the sequences as follows
        // 1. use sliding window of 2
        // 2. if [i] == [i + 1] => break main loop
        // 3. if [i] distance between [i + 1] is more than 3 => break main loop
        // 4. set the check condition: sequence of numbers is either increasing or decreasing (do this only with the first set of numbers)
        // 5. if the sequence is increasing, the first number must be smaller than the second number and not by more than 3
        // 6. if the sequence is decreasing, the first number must be larger than the second number and not by more than 3
        // 7. if looping through the entire row, the sequence is valid, increment a counter

        var index: usize = 1;
        // -1 unset
        // 0 increasing
        // 1 decreasing
        var codeflowType: i8 = -1;
        while (index < segmentArray.items.len) : (index += 1) {
            // std.log.debug("index: {d}", .{index});
            // std.log.debug("segment: {d}", .{segmentArray.items[index - 1]});
            std.log.debug("[{d}] checking: {d} - {d}, ABS ({d})", .{ index, segmentArray.items[index - 1], segmentArray.items[index], absU32(segmentArray.items[index - 1], segmentArray.items[index]) });
            if (segmentArray.items[index - 1] == segmentArray.items[index]) {
                std.log.debug("EQUALS - BREAK!", .{});
                break;
            }
            if (codeflowType == -1) {
                if (segmentArray.items[index - 1] < segmentArray.items[index]) {
                    codeflowType = 0;
                } else {
                    codeflowType = 1;
                }
            }

            if (absU32(segmentArray.items[index - 1], segmentArray.items[index]) > 3) {
                std.log.debug("ABS CHECK - BREAK!", .{});
                break;
            }

            if (codeflowType == 0 and (segmentArray.items[index - 1] < segmentArray.items[index])) {
                // continue
                // do an ABS check so that the difference is not more than 3

            } else if (codeflowType == 1 and (segmentArray.items[index - 1] > segmentArray.items[index])) {
                // continue
            } else {
                std.log.debug("CODEFLOW CHANGE - BREAK!", .{});
                break;
            }

            if (index == segmentArray.items.len - 1) {
                std.log.debug("incrementing!", .{});
                validSequences += 1;
            }
        }
    }

    std.log.debug("Valid Sequences: {d}", .{validSequences});

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
    var expected: usize = 0;

    const fileName = "../test.txt";
    const allocator = std.heap.page_allocator;

    const exePath = try captureArgs(allocator);

    const filePath = try buildFilePath(allocator, exePath, fileName);
    std.log.debug("File Path: {s}", .{filePath});

    const file = std.fs.openFileAbsolute(filePath, .{ .mode = .read_only }) catch |err| {
        switch (err) {
            else => {
                std.log.err("Unknown error {}", .{err});
                return;
            },
        }
    };
    defer file.close();

    const reader = file.reader();
    var bufferedReader = std.io.bufferedReader(reader);
    var lineReader = bufferedReader.reader();

    // guesstimate of 50 bytes per line
    while (try lineReader.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |line| {
        defer allocator.free(line);

        // split by three spaces
        var splitLine = std.mem.splitScalar(u8, line, ' ');
        var segmentArray = std.ArrayList(u32).init(allocator);
        defer segmentArray.deinit();

        while (splitLine.next()) |segment| {
            const number = try std.fmt.parseInt(u32, segment, 10);
            _ = try segmentArray.append(number);
        }

        // now we have a row of numbers
        // check the sequences as follows
        // 1. use sliding window of 2
        // 2. if [i] == [i + 1] => break main loop
        // 3. if [i] distance between [i + 1] is more than 3 => break main loop
        // 4. set the check condition: sequence of numbers is either increasing or decreasing (do this only with the first set of numbers)
        // 5. if the sequence is increasing, the first number must be smaller than the second number and not by more than 3
        // 6. if the sequence is decreasing, the first number must be larger than the second number and not by more than 3
        // 7. if looping through the entire row, the sequence is valid, increment a counter

        var index: usize = 1;
        // -1 unset
        // 0 increasing
        // 1 decreasing
        var codeflowType: i8 = -1;
        while (index < segmentArray.items.len) : (index += 1) {
            // std.log.debug("index: {d}", .{index});
            // std.log.debug("segment: {d}", .{segmentArray.items[index - 1]});
            std.log.debug("[{d}] checking: {d} - {d}, ABS ({d})", .{ index, segmentArray.items[index - 1], segmentArray.items[index], absU32(segmentArray.items[index - 1], segmentArray.items[index]) });
            if (segmentArray.items[index - 1] == segmentArray.items[index]) {
                std.log.debug("EQUALS - BREAK!", .{});
                break;
            }
            if (codeflowType == -1) {
                if (segmentArray.items[index - 1] < segmentArray.items[index]) {
                    codeflowType = 0;
                } else {
                    codeflowType = 1;
                }
            }

            if (absU32(segmentArray.items[index - 1], segmentArray.items[index]) > 3) {
                std.log.debug("ABS CHECK - BREAK!", .{});
                break;
            }

            if (codeflowType == 0 and (segmentArray.items[index - 1] < segmentArray.items[index])) {
                // continue
                // do an ABS check so that the difference is not more than 3

            } else if (codeflowType == 1 and (segmentArray.items[index - 1] > segmentArray.items[index])) {
                // continue
            } else {
                std.log.debug("CODEFLOW CHANGE - BREAK!", .{});
                break;
            }

            if (index == segmentArray.items.len - 1) {
                std.log.debug("incrementing!", .{});
                expected += 1;
            }
        }
    }

    try std.testing.expectEqual(2, expected);
}
