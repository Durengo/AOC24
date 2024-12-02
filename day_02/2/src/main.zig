const std = @import("std");
const math = @import("math");

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

    const reader = file.reader();
    var bufferedReader = std.io.bufferedReader(reader);
    var lineReader = bufferedReader.reader();

    var data = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer data.deinit();

    // guesstimate of 50 bytes per line
    while (try lineReader.readUntilDelimiterOrEofAlloc(allocator, '\n', 50)) |line| {
        defer allocator.free(line);
        var splitLine = std.mem.splitScalar(u8, line, ' ');
        var segmentArray = std.ArrayList(u32).init(allocator);
        defer segmentArray.deinit();

        while (splitLine.next()) |segment| {
            const number = try std.fmt.parseInt(u32, segment, 10);
            _ = try segmentArray.append(number);
        }

        const segmentClone = try segmentArray.clone();
        _ = try data.append(segmentClone);
    }

    // logic
    var valid_sequences: u32 = 0;
    for (data.items) |segmentArray| {
        std.log.debug("--------------\n", .{});
        std.log.debug("Segment: {any}", .{segmentArray.items});
        var sequence_flow: i8 = -1;
        var faultyIndex: i32 = dampener(segmentArray, &sequence_flow);
        if (faultyIndex == -1) {
            std.log.debug("Valid Sequence", .{});
            valid_sequences += 1;
        } else {
            std.log.err("Faulty Index: {d}", .{faultyIndex});
            const trueFaultyIndex = try findTrueFaultyIndex(segmentArray);
            std.log.err("True Faulty Index: {d}", .{trueFaultyIndex});
            if (trueFaultyIndex != -1) {
                var lastPossibleSegment = std.ArrayList(u32).init(allocator);
                defer lastPossibleSegment.deinit();

                for (segmentArray.items, 0..) |element, i| {
                    if (i != trueFaultyIndex) {
                        _ = try lastPossibleSegment.append(element);
                    }
                }

                std.log.debug("New Segment: {any}", .{lastPossibleSegment.items});

                sequence_flow = -1;
                faultyIndex = dampener(lastPossibleSegment, &sequence_flow);
                if (faultyIndex == -1) {
                    std.log.debug("Valid Sequence", .{});
                    valid_sequences += 1;
                }
            }
        }
    }

    std.log.debug("Valid Sequences: {d}", .{valid_sequences});

    return return_value;
}

fn findTrueFaultyIndex(segment_array: std.ArrayList(u32)) !i32 {
    const len = segment_array.items.len;

    for (0..len) |faultyIdx| {
        var modifiedArray = std.ArrayList(u32).init(std.heap.page_allocator);
        defer modifiedArray.deinit();

        for (segment_array.items, 0..) |item, i| {
            if (i != faultyIdx) {
                _ = try modifiedArray.append(item);
            }
        }

        var temp_sequence_flow: i8 = -1;
        const faultyIndex = dampener(modifiedArray, &temp_sequence_flow);
        if (faultyIndex == -1) {
            return @intCast(faultyIdx);
        }
    }

    return -1;
}

fn dampener(segment_array: std.ArrayList(u32), sequence_flow: *i8) i32 {
    var index: usize = 0;
    const len = segment_array.items.len;

    while (index + 1 < len) : (index += 1) {
        const current: i64 = @intCast(segment_array.items[index]);
        const next: i64 = @intCast(segment_array.items[index + 1]);
        const diff: i64 = next - current;
        const abs_diff = if (diff < 0) -diff else diff;
        // std.log.debug("next: {d}, current: {d}, diff: {d}, abs_diff: {d}", .{ next, current, diff, abs_diff });

        if (abs_diff == 0 or abs_diff > 3) {
            return @intCast(index);
        }

        if (sequence_flow.* == -1) {
            sequence_flow.* = if (diff > 0) 0 else 1;
        } else {
            if ((sequence_flow.* == 0 and diff <= 0) or (sequence_flow.* == 1 and diff >= 0)) {
                return @intCast(index);
            }
        }
    }

    return -1;
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
