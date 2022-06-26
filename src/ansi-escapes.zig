const std = @import("std");

const Allocator = std.mem.Allocator;

// pub const Control = enum(u8) {
//     reset
// }

const ansi_reset = "\u{001b}[0m";

/// Bright Foreground Colors.
pub const BColor = enum(u8) {
    black = 90,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    pub fn format(self: BColor, alloc: Allocator, text: []const u8) ![]const u8 {
        return formatCode(@enumToInt(self), alloc, text);
    }
};

/// Standard Foreground Colors.
pub const Color = enum(u8) {
    black = 30,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    pub fn format(self: Color, alloc: Allocator, text: []const u8) ![]const u8 {
        return formatCode(@enumToInt(self), alloc, text);
    }
};

/// Bright Background Colors.
pub const BgBColor = enum(u8) {
    black = 100,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    pub fn format(self: BColor, alloc: Allocator, text: []const u8) ![]const u8 {
        return formatCode(@enumToInt(self), alloc, text);
    }
};

/// Standard Background Colors.
pub const BgColor = enum(u8) {
    black = 40,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    pub fn format(self: Color, alloc: Allocator, text: []const u8) ![]const u8 {
        return formatCode(@enumToInt(self), alloc, text);
    }
};

/// Format text with the given escape code.
pub fn formatCode(code: u8, alloc: Allocator, text: []const u8) ![]const u8 {
    var prefix_buffer: [6]u8 = undefined;
    const prefix = std.fmt.bufPrint(&prefix_buffer, "\u{001b}[{d}m", .{code}) catch unreachable;

    const size = comptime prefix.len + ansi_reset.len;

    var bytes = try alloc.alloc(u8, text.len + size);
    std.mem.copy(u8, bytes, prefix[0..]);
    std.mem.copy(u8, bytes[prefix.len..], text);
    std.mem.copy(u8, bytes[prefix.len + text.len ..], ansi_reset);
    return bytes;
}

const expectEqual = std.testing.expectEqualStrings;

test "Color.format" {
    const alloc = std.testing.allocator;
    var example1 = try Color.black.format(alloc, "Hello");
    defer alloc.free(example1);
    try expectEqual(@as([]const u8, "\u{001b}[30mHello" ++ ansi_reset), example1);

    var example2 = try Color.red.format(alloc, "Foo Bar");
    defer alloc.free(example2);
    try expectEqual(@as([]const u8, "\u{001b}[31mFoo Bar" ++ ansi_reset), example2);

    var example3 = try Color.white.format(alloc, "");
    defer alloc.free(example3);
    try expectEqual(@as([]const u8, "\u{001b}[37m" ++ ansi_reset), example3);
}

test "BColor.format" {
    const alloc = std.testing.allocator;
    var example1 = try BColor.black.format(alloc, "Bright Colors");
    defer alloc.free(example1);
    try expectEqual(@as([]const u8, "\u{001b}[90mBright Colors" ++ ansi_reset), example1);

    var example2 = try BColor.white.format(alloc, "");
    defer alloc.free(example2);
    try expectEqual(@as([]const u8, "\u{001b}[97m" ++ ansi_reset), example2);
}
