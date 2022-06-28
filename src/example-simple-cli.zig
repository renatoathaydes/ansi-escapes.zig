/// Demo Application
const std = @import("std");
const ansi = @import("ansi-escapes.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Color = ansi.Color;
const Style = ansi.DisplayStyle;

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

var prompt_value: []const u8 = "User> ".*[0..];

fn prompt(alloc: Allocator) ![]const u8 {
    return try Color.blue.apply(alloc, prompt_value);
}

fn writeAndFree(alloc: Allocator, bytes: []const u8) !void {
    defer alloc.free(bytes);
    try stdout.writeAll(bytes);
}

fn selectEnum(comptime t: type) fn (buffer: []const u8) anyerror!?t {
    const T = @typeInfo(t);
    return struct {
        fn choose(buffer: []const u8) anyerror!?t {
            inline for (T.Enum.fields) |field| {
                if (std.mem.containsAtLeast(u8, buffer, 1, field.name)) {
                    return @intToEnum(t, field.value);
                }
            }
            return null;
        }
    }.choose;
}

fn showWelcomeMessage() !void {
    return stdout.writeAll(
        \\ansi-escapes.zig Demo CLI
        \\
        \\It echo backs the text you enter, but styles it if it contains the name of a color.
        \\Lines starting with '/' are commands.
        \\
        \\Available commands:
        \\  - /bg <color>    - the background color
        \\  - /fg <color>    - the foreground color
        \\  - /st <style>    - the style
        \\  - /quit          - quit (Ctrl+d also quits)
        \\
    );
}

pub fn main() !void {
    try showWelcomeMessage();

    const max_line_size = 1024;

    const alloc = init: {
        var memory: [max_line_size + 256]u8 = undefined;
        var allocator = std.heap.FixedBufferAllocator.init(&memory);
        break :init allocator.allocator();
    };

    var fgColor: ?Color = null;
    var bgColor: ?Color = null;
    var style: ?Style = null;
    const no_style = [0]Style{};

    try writeAndFree(alloc, try prompt(alloc));

    while (try stdin.readUntilDelimiterOrEofAlloc(alloc, '\n', max_line_size)) |buffer| {
        defer alloc.free(buffer);
        if (std.mem.startsWith(u8, buffer, "/")) {
            const cmd = buffer[1..];
            if (std.mem.startsWith(u8, cmd, "fg ")) {
                fgColor = try selectEnum(Color)(buffer);
                if (fgColor == null) {
                    try stdout.writeAll("Invalid color, unset fg!\n");
                }
            } else if (std.mem.startsWith(u8, cmd, "bg ")) {
                bgColor = try selectEnum(Color)(buffer);
                if (bgColor == null) {
                    try stdout.writeAll("Invalid color, unset bg!\n");
                }
            } else if (std.mem.startsWith(u8, cmd, "st ")) {
                style = try selectEnum(Style)(buffer);
                if (style == null) {
                    try stdout.writeAll("Invalid style, unset st!\n");
                }
            } else if (std.mem.eql(u8, cmd, "quit")) {
                break;
            } else {
                try stdout.writeAll("Unknown command.\n");
            }
        } else {
            try writeAndFree(alloc, try ansi.style(alloc, buffer, .{
                .fg = fgColor,
                .bg = bgColor,
                .styles = if (style) |st| &.{st} else &no_style,
            }));
            try stdout.writeAll("\n");
        }
        try writeAndFree(alloc, try prompt(alloc));
    }
}
