const std = @import("std");
const utils = @import("./utils.zig");
const Allocator = std.mem.Allocator;

const expectEqualSlices = std.testing.expectEqualSlices;

const reset = utils.reset;

const FgOrBg = enum(u8) {
    Fg = 38,
    Bg = 48,
};

/// A 24-bit color with Red, Green and Blue components.
pub const RGBColor = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,

    /// Apply 24-bit Color to the text foreground.
    pub fn apply(self: RGBColor, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, self, .Fg, text);
    }

    /// Apply 24-bit Color to the text background.
    pub fn applyBg(self: RGBColor, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, self, .Bg, text);
    }

    fn len(self: RGBColor) usize {
        const r = utils.digitLen(self.red);
        const g = utils.digitLen(self.green);
        const b = utils.digitLen(self.blue);
        return r + g + b;
    }
};

fn styleText(alloc: Allocator, color: RGBColor, fgbg: FgOrBg, text: []const u8) ![]const u8 {
    // ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩m
    var buffer = try alloc.alloc(u8, 10 + color.len() + text.len + reset.len);
    const c = @enumToInt(fgbg);
    
    return std.fmt.bufPrint(buffer, "\u{001b}[{d};2;{d};{d};{d}m{s}" ++ reset,
                         .{c, color.red, color.green, color.blue, text});
}

test "RBGColor" {
    const alloc = std.testing.allocator;

    var example1 = try (RGBColor{}).apply(alloc, "foo");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[38;2;0;0;0mfoo\u{001b}[m", example1);

    var example2 = try (RGBColor{.red = 2, .green = 42, .blue = 255}).apply(alloc, "bar");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[38;2;2;42;255mbar\u{001b}[m", example2);

    var example3 = try (RGBColor{.red = 254, .green = 98, .blue = 1}).applyBg(alloc, "bar");
    defer alloc.free(example3);
    try expectEqualSlices(u8, "\u{001b}[48;2;254;98;1mbar\u{001b}[m", example3);
}
