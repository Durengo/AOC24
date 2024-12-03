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

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    const read_result = try file.readAll(buffer);

    std.log.debug("Read Result: {any}", .{read_result});

    var m = false;
    var u = false;
    var l = false;
    var open_paren = false;
    var middle_comma = false;
    var close_paren = false;
    var first_number: i32 = 0;
    var first_number_location: i32 = 0;
    var second_number: i32 = 0;
    var second_number_location: i32 = 0;
    var final_result: i32 = 0;

    var count: i32 = -1;

    for (buffer) |byte| {
        if (close_paren) {
            std.log.debug("Successful set found!", .{});
            count = -1;
            m = false;
            u = false;
            l = false;
            open_paren = false;
            middle_comma = false;
            close_paren = false;

            std.log.debug("-----\n\nFirst Number: {d} | Second Number: {d} = {d}\n\n-----", .{ first_number, second_number, first_number * second_number });

            final_result += first_number * second_number;
            first_number = 0;
            first_number_location = 0;
            second_number = 0;
            second_number_location = 0;
        }
        std.log.debug("Status: count: {d} m: {any} | u: {any} | l: {any} | open_paren: {any} | middle_comma: {any} | close_paren: {any} | first number: {d} | second number: {d} | final result: {d}", .{ count, m, u, l, open_paren, middle_comma, close_paren, first_number, second_number, final_result });

        const char: u8 = byte;
        std.log.debug("Char: {c}", .{char});

        // find first 'mul('
        if (count == -1) {
            if (char == 'm') {
                m = true;
                count += 1;
                continue;
            }
        } else if (count == 0) {
            if (char == 'u') {
                u = true;
                count += 1;
                continue;
            } else {
                count = -1;
                m = false;
                u = false;
                continue;
            }
        } else if (count == 1) {
            if (char == 'l') {
                l = true;
                count += 1;
                continue;
            } else {
                count = -1;
                m = false;
                u = false;
                l = false;
                continue;
            }
        } else if (count == 2) {
            if (char == '(') {
                open_paren = true;
                count += 1;
                continue;
            } else {
                count = -1;
                m = false;
                u = false;
                l = false;
                open_paren = false;
                continue;
            }
        }

        // first set of 'mul(' found, proceed by parsing numbers
        if (count > 2) {
            std.log.debug("Parsing numbers", .{});
            // Try parsing into number
            const slice: []const u8 = &[_]u8{char};
            var number: i32 = 0;

            const result = std.fmt.parseInt(i32, slice, 10) catch {
                std.log.debug("Caught error", .{});
                // Handle parsing failure
                if (count > 3) {
                    if (char == ',') {
                        middle_comma = true;
                        count += 1;
                        continue;
                    } else if (middle_comma and char == ')') {
                        close_paren = true;
                        count += 1;
                        continue;
                    } else {
                        count = -1;
                        m = false;
                        u = false;
                        l = false;
                        open_paren = false;
                        middle_comma = false;
                        close_paren = false;
                        first_number = 0;
                        first_number_location = 0;
                        second_number = 0;
                        second_number_location = 0;
                        continue;
                    }
                } else {
                    count = -1;
                    m = false;
                    u = false;
                    l = false;
                    open_paren = false;
                    middle_comma = false;
                    close_paren = false;
                    first_number = 0;
                    first_number_location = 0;
                    second_number = 0;
                    second_number_location = 0;
                    continue;
                }
                return_value = 1;
                return return_value;
            };

            std.log.debug("Parsed number: {d}", .{result});

            count += 1;

            number = result;

            if (!middle_comma) {
                first_number = first_number * 10 + number;
                // if (first_number_location == 0) {
                //     first_number += number;
                // } else {
                //     first_number += number * (std.math.pow(i32, 10, first_number_location));
                // }
                // first_number_location += 1;
            } else {
                second_number = second_number * 10 + number;
                // if (second_number_location == 0) {
                //     second_number += number;
                // } else {
                //     second_number += number * (std.math.pow(i32, 10, second_number_location));
                // }
                // second_number_location += 1;
            }

            std.log.debug("First Number: {d} | Second Number: {d}", .{ first_number, second_number });
        }
    }

    std.log.debug("Final Result: {d}", .{final_result});

    // const file_as_string: []const u8 = buffer;
    // std.log.debug("File as string: {s}", .{file_as_string});

    // var splits = std.mem.tokenizeSequence(u8, buffer, "abcdefghijknopqrstvwxyz!@#$%^&*_+|:;<>?/., ");
    // std.log.debug("Splits: {any}", .{splits});
    // // const matches: []const []const u8 = &[_][]const u8{};

    // while (splits.next()) |segment| {
    //     std.log.debug("Segment: {s}", .{segment});
    // }

    // var indices = std.ArrayList(usize).init(std.heap.page_allocator);
    // defer indices.deinit();

    // const substr = "mul(";
    // var start: usize = 0;
    // while (start < file_as_string.len) {
    //     std.log.debug("--------", .{});
    //     const rest = file_as_string[start..];
    //     const idx = std.mem.indexOf(u8, rest, substr);
    //     std.log.debug("start: {any} | index: {any} | rest: {s}", .{ start, idx, rest });
    //     if (idx) |i| {
    //         const index_in_str = start + i;
    //         std.log.debug("[{d}] index_in_str: {any}", .{ i, index_in_str });
    //         try indices.append(index_in_str);
    //         start = index_in_str + substr.len;
    //         std.log.debug("new start: {any}", .{start});
    //     } else {
    //         break;
    //     }
    // }

    // for (indices.items) |index| {
    //     std.debug.print("Found 'mul(' at index {}\n", .{index});
    // }

    return return_value;
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
