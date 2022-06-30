const std = @import("std");
const utils = @import("./utils.zig");
const Allocator = std.mem.Allocator;

const expectEqualSlices = std.testing.expectEqualSlices;

const reset = utils.reset;

const FgOrBg = enum(u8) {
    Fg = 38,
    Bg = 48,
};

/// A 8-bit color.
pub const Color8 = struct {
    value: u8 = 0,

    /// Apply 8-bit Color to the text foreground.
    pub fn apply(self: Color8, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, self, .Fg, text);
    }

    /// Apply 8-bit Color to the text background.
    pub fn applyBg(self: Color8, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, self, .Bg, text);
    }

    fn len(self: Color8) usize {
        return utils.digitLen(self.value);
    }
};

fn styleText(alloc: Allocator, color: Color8, fgbg: FgOrBg, text: []const u8) ![]const u8 {
    // ESC[38;5;⟨v⟩m
    var buffer = try alloc.alloc(u8, 8 + color.len() + text.len + reset.len);
    const c = @enumToInt(fgbg);
    
    return std.fmt.bufPrint(buffer, "\u{001b}[{d};5;{d}m{s}" ++ reset,
                         .{c, color.value, text});
}

test "Color8" {
    const alloc = std.testing.allocator;

    var example1 = try (Color8{}).apply(alloc, "foo");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[38;5;0mfoo\u{001b}[m", example1);

    var example2 = try (Color8{.value = 42}).apply(alloc, "bar");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[38;5;42mbar\u{001b}[m", example2);

    var example3 = try (Color8{.value = 255}).applyBg(alloc, "zort");
    defer alloc.free(example3);
    try expectEqualSlices(u8, "\u{001b}[48;5;255mzort\u{001b}[m", example3);
}
