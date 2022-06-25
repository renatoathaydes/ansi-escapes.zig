/// Demo Application
const std = @import("std");
const ansi = @import("./ansi-escapes.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Color = ansi.Color;

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

var prompt_value: []const u8 = "User> ".*[0..];

fn prompt(alloc: Allocator) ![]const u8 {
    return try Color.blue.format(alloc, prompt_value);
}

fn writeAndFree(alloc: Allocator, bytes: []const u8) !void {
    defer alloc.free(bytes);
    try stdout.writeAll(bytes);
}

const printFn = fn (alloc: Allocator, buffer: []const u8) anyerror!void;
const printFnSelector = fn (buffer: []const u8) printFn;

fn printColor(comptime color: Color) printFn {
    return struct {
        fn doit(alloc: Allocator, buffer: []const u8) !void {
            const text = try color.format(alloc, buffer);
            defer alloc.free(text);
            return stdout.writeAll(text);
        }
    }.doit;
}

fn printSimple(_: Allocator, buffer: []const u8) !void {
    return stdout.writeAll(buffer);
}

fn selectPrintFn() printFnSelector {
    return struct {
        fn doit(buffer: []const u8) printFn {
            const T = @typeInfo(Color);
            inline for (T.Enum.fields) |field| {
                if (std.mem.startsWith(u8, buffer, field.name)) {
                    return printColor(@intToEnum(Color, field.value));
                }
            }
            return printSimple;
        }
    }.doit;
}

pub fn main() !void {
    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();
    var alloc = allocator.allocator();
    const max_line_size = 1000 * 1024;

    const print = selectPrintFn();

    try writeAndFree(alloc, try prompt(alloc));

    while (try stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', max_line_size)) |buffer| {
        defer alloc.free(buffer);
        try print(buffer)(alloc, buffer);
        try stdout.writeAll("\n");
        try writeAndFree(alloc, try prompt(alloc));
    }

    try stdout.print("\nGoodbye!\n", .{});
}
