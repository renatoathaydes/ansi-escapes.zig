/// Demo Application
const std = @import("std");
const ansi = @import("ansi-escapes.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Color = ansi.Color;
const BColor = ansi.BColor;
const BgColor = ansi.BgColor;
const BgBColor = ansi.BgBColor;

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

fn printSimple(_: Allocator, buffer: []const u8) !void {
    return stdout.writeAll(buffer);
}

fn selectPrintFn(enum_type: anytype) printFn {
    const T = @typeInfo(enum_type);
    return struct {
        fn print(alloc: Allocator, buffer: []const u8) anyerror!void {
            inline for (T.Enum.fields) |field| {
                if (std.mem.containsAtLeast(u8, buffer, 1, field.name)) {
                    const b = try ansi.formatCode(field.value, alloc, buffer);
                    return writeAndFree(alloc, b);
                }
            }
            try printSimple(alloc, buffer);
        }
    }.print;
}

fn showWelcomeMessage() !void {
    return stdout.writeAll(
        \\ansi-escapes.zig Demo CLI
        \\
        \\It echo backs the text you enter, but styles it if it contains the name of a color.
        \\Lines starting with '/' are commands.
        \\
        \\Available commands:
        \\  - /back          - style the background color
        \\  - /bright        - style foreground, bright color
        \\  - /bright back   - style background, bright color
        \\  - /default       - style the foreground color
        \\  - /quit          - quit (Ctrl+d also quits)
        \\
    );
}

pub fn main() !void {
    try showWelcomeMessage();

    var allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator.deinit();
    var alloc = allocator.allocator();
    const max_line_size = 1000 * 1024;

    const printC = selectPrintFn(Color);
    const printB = selectPrintFn(BColor);
    const printBgC = selectPrintFn(BgColor);
    const printBgB = selectPrintFn(BgBColor);

    var print = printC;

    try writeAndFree(alloc, try prompt(alloc));

    while (try stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', max_line_size)) |buffer| {
        defer alloc.free(buffer);
        if (std.mem.startsWith(u8, buffer, "/")) {
            const cmd = buffer[1..];
            if (std.mem.eql(u8, cmd, "bright")) {
                print = printB;
            } else if (std.mem.eql(u8, cmd, "bright back")) {
                print = printBgB;
            } else if (std.mem.eql(u8, cmd, "back")) {
                print = printBgC;
            } else if (std.mem.eql(u8, cmd, "default")) {
                print = printC;
            } else if (std.mem.eql(u8, cmd, "quit")) {
                break;
            } else {
                try stdout.writeAll("Unknown command.\n");
            }
        } else {
            try print(alloc, buffer);
            try stdout.writeAll("\n");
        }
        try writeAndFree(alloc, try prompt(alloc));
    }
}
