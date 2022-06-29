const std = @import("std");
const utils = @import("./utils.zig");
const rgb = @import("./rgb.zig");

const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Allocator = std.mem.Allocator;

const reset = utils.reset;

/// A 24-bit color with Red, Green and Blue components.
pub const RGBColor = rgb.RGBColor;

/// Display style. Many modifiers can be applied at the same time.
pub const DisplayStyle = enum(u8) {
    bold = 1,
    faint,
    italic,
    underline,
    blinking,
    fast_blinking,
    reverse,
    hidden,
    strikeThrough,

    /// Apply DisplayStyle to the text.
    pub fn apply(self: DisplayStyle, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, &[_]u8{@enumToInt(self)}, text);
    }
};

/// Standard Colors.
pub const Color = enum(u8) {
    black = 30,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    b_black = 90,
    b_red,
    b_green,
    b_yellow,
    b_blue,
    b_magenta,
    b_cyan,
    b_white,

    /// Apply Standard Color to the text foreground.
    pub fn apply(self: Color, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, &[_]u8{self.fg()}, text);
    }

    /// Apply Standard Color to the text background.
    pub fn applyBg(self: Color, alloc: Allocator, text: []const u8) ![]const u8 {
        return styleText(alloc, &[_]u8{self.bg()}, text);
    }

    /// Code for this color when used as foreground.
    pub fn fg(self: Color) u8 {
        return @enumToInt(self);
    }

    /// Code for this color when used as background.
    pub fn bg(self: Color) u8 {
        return self.fg() + 10;
    }

    /// Convert this color to the bright version of it.
    /// If this color is already bright, returns itself.
    pub fn toBright(self: Color) Color {
        if (@enumToInt(self) >= @enumToInt(Color.b_black)) {
            return self;
        }
        return @intToEnum(Color, @enumToInt(self) + 60);
    }
};

test "Color.apply" {
    const alloc = std.testing.allocator;
    var example1 = try Color.black.apply(alloc, "Hello");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[30mHello" ++ reset, example1);

    var example2 = try Color.red.apply(alloc, "Foo Bar");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[31mFoo Bar" ++ reset, example2);

    var example3 = try Color.b_white.apply(alloc, "");
    defer alloc.free(example3);
    try expectEqualSlices(u8, "\u{001b}[97m" ++ reset, example3);
}

test "Color.applyBg" {
    const alloc = std.testing.allocator;
    var example1 = try Color.black.applyBg(alloc, "Hello");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[40mHello" ++ reset, example1);

    var example2 = try Color.red.applyBg(alloc, "Foo Bar");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[41mFoo Bar" ++ reset, example2);

    var example3 = try Color.b_white.applyBg(alloc, "");
    defer alloc.free(example3);
    try expectEqualSlices(u8, "\u{001b}[107m" ++ reset, example3);
}

test "Color.toBright" {
    const alloc = std.testing.allocator;
    var example1 = try Color.red.toBright().apply(alloc, "normal color");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[91mnormal color" ++ reset, example1);

    var example2 = try Color.b_green.toBright().apply(alloc, "already bright color");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[92malready bright color" ++ reset, example2);
}

pub const Options = struct {
    bg: ?Color = null,
    fg: ?Color = null,
    styles: []const DisplayStyle = &[0]DisplayStyle{},
};

fn findCodes(alloc: Allocator, options: Options) ![]const u8 {
    var codesLen = options.styles.len;
    if (options.bg != null and options.fg != null) {
        // we'll add a 0 between the bg and the fg sequence
        codesLen += 3;
    } else if (options.bg != null or options.fg != null) {
        codesLen += 1;
    }
    var codes = try alloc.alloc(u8, codesLen);
    var index: usize = 0;
    for (options.styles) |st| {
        codes[index] = @enumToInt(st);
        index += 1;
    }
    if (options.fg) |fg| {
        codes[index] = fg.fg();
        index += 1;
    }
    if (options.bg != null and options.fg != null) {
        codes[index] = 0;
        index += 1;
    }
    if (options.bg) |bg| {
        codes[index] = bg.bg();
        index += 1;
    }
    std.debug.assert(codes.len == index);

    return codes;
}

test "findCodes (empty)" {
    try expectEqualSlices(u8, &[0]u8{}, try findCodes(std.testing.allocator, .{}));
}

test "findCodes (fg)" {
    const codes = try findCodes(std.testing.allocator, .{ .fg = .black });
    defer std.testing.allocator.free(codes);
    try expectEqualSlices(u8, &[1]u8{30}, codes);
}

test "findCodes (fg+style)" {
    const codes = try findCodes(std.testing.allocator, .{
        .fg = .b_black,
        .styles = &[_]DisplayStyle{.bold},
    });
    defer std.testing.allocator.free(codes);
    try expectEqualSlices(u8, &[2]u8{ 1, 90 }, codes);
}

test "findCodes (bg)" {
    const codes = try findCodes(std.testing.allocator, .{ .bg = .black });
    defer std.testing.allocator.free(codes);
    try expectEqualSlices(u8, &[1]u8{40}, codes);
}

test "findCodes (fg+bg)" {
    const codes = try findCodes(std.testing.allocator, .{
        .fg = .blue,
        .bg = .yellow,
    });
    defer std.testing.allocator.free(codes);
    try expectEqualSlices(u8, &[_]u8{ 34, 0, 43 }, codes);
}

test "findCodes (fg+bg+styles)" {
    const codes = try findCodes(std.testing.allocator, .{
        .fg = .b_magenta,
        .bg = .b_white,
        .styles = &[_]DisplayStyle{ .italic, .blinking, .underline },
    });
    defer std.testing.allocator.free(codes);
    try expectEqualSlices(u8, &[_]u8{ 3, 5, 4, 95, 0, 107 }, codes);
}

/// Style the text with the given code sequences.
/// A 0 value represents a "break" between different code sequences.
/// For example, the array [1, 2, 0, 3] represents two code sequences,
/// [1, 2] and [3] and would result in 'ESC[1;2mESC[3m...'.
fn styleText(alloc: Allocator, code_sequences: []const u8, text: []const u8) ![]const u8 {
    if (code_sequences.len == 0) {
        return text;
    }

    // each code sequence needs a ';' between each value, so we add one for each
    // code that is not the first in a code sequence.
    var first_in_sequence = true;

    // initial ESC[ + _ + m
    var total_size: usize = 3;

    for (code_sequences) |code| {
        if (code == 0) {
            // ESC[ + _ + 'm'
            total_size += 3;
            first_in_sequence = true;
        } else {
            total_size += utils.digitLen(code);
            if (!first_in_sequence) {
                total_size += 1; // the ';' between codes
            }
            first_in_sequence = false;
        }
    }

    // size = current + text + reset.len
    var buffer = try alloc.alloc(u8, total_size + text.len + reset.len);

    buffer[0] = '\u{001b}';
    buffer[1] = '[';
    var index: usize = 2;
    first_in_sequence = false;

    for (code_sequences) |code, i| {
        if (first_in_sequence) { // end previous sequence, start new
            buffer[index] = 'm';
            index += 1;
            buffer[index] = '\u{001b}';
            index += 1;
            buffer[index] = '[';
            index += 1;
        }
        if (code == 0) {
            first_in_sequence = true;
        } else {
            var buf = [_]u8{ 0, 0, 0 };
            const c = try utils.codeToString(code, &buf);
            std.mem.copy(u8, buffer[index..], c);
            index += c.len;
            // lookahead to see if the separator is needed
            if (i < code_sequences.len - 1 and code_sequences[i + 1] != 0) {
                buffer[index] = ';';
                index += 1;
            }
            first_in_sequence = false;
        }
    }

    buffer[index] = 'm';
    index += 1;
    std.mem.copy(u8, buffer[index..], text);
    index += text.len;
    std.mem.copy(u8, buffer[index..], reset[0..]);
    index += reset.len;

    std.debug.assert(buffer.len == index);
    return buffer;
}

/// Style the text with the given options.
/// A reset code is appended at the end of the result.
/// Memory is allocated for the return value and must be freed by the caller.
pub fn style(alloc: Allocator, text: []const u8, options: Options) ![]const u8 {
    const all_codes = try findCodes(alloc, options);
    defer alloc.free(all_codes);
    return styleText(alloc, all_codes, text);
}

test "styleText" {
    const styles = [3]u8{ 3, 1, 2 };
    const alloc = std.testing.allocator;

    var example1 = try styleText(alloc, styles[0..0], "");
    defer alloc.free(example1);
    try expectEqualSlices(u8, "", example1);

    var example2 = try styleText(alloc, styles[0..1], "Italic");
    defer alloc.free(example2);
    try expectEqualSlices(u8, "\u{001b}[3mItalic" ++ reset, example2);

    var example3 = try styleText(alloc, styles[0..], "Italic, bold and faint");
    defer alloc.free(example3);
    try expectEqualSlices(u8, "\u{001b}[3;1;2mItalic, bold and faint" ++ reset, example3);
}

test "style (empty string and no styles)" {
    const alloc = std.testing.allocator;

    var example1 = try style(alloc, "", .{});
    defer alloc.free(example1);
    try expectEqualSlices(u8, "", example1);
}

test "style (empty string and one style)" {
    const alloc = std.testing.allocator;

    var example1 = try style(alloc, "", .{
        .styles = &[_]DisplayStyle{.blinking},
    });
    defer alloc.free(example1);
    try expectEqualSlices(u8, "\u{001b}[5m" ++ reset, example1);
}

test "style (only fg)" {
    const alloc = std.testing.allocator;
    var example = try style(alloc, "hello", .{ .fg = .black });
    defer alloc.free(example);
    try expectEqualSlices(u8, "\u{001b}[30mhello" ++ reset, example);
}

test "style (only bg)" {
    const alloc = std.testing.allocator;
    var example = try style(alloc, "hello", .{ .bg = .red });
    defer alloc.free(example);
    try expectEqualSlices(u8, "\u{001b}[41mhello" ++ reset, example);
}

test "style (fg and bg)" {
    const alloc = std.testing.allocator;
    var example = try style(alloc, "hello", .{
        .fg = .b_green,
        .bg = .b_black,
    });
    defer alloc.free(example);
    try expectEqualSlices(u8, "\u{001b}[92m\u{001b}[100mhello" ++ reset, example);
}

test "style (fg and one style)" {
    const alloc = std.testing.allocator;
    var example = try style(alloc, "hello", .{
        .fg = .b_magenta,
        .styles = &[_]DisplayStyle{
            DisplayStyle.italic,
        },
    });
    defer alloc.free(example);
    try expectEqualSlices(u8, "\u{001b}[3;95mhello" ++ reset, example);
}

test "style (fg, bg, many styles)" {
    const alloc = std.testing.allocator;
    var example = try style(alloc, "hello", .{
        .fg = .blue,
        .bg = .b_yellow,
        .styles = &[_]DisplayStyle{
            .faint,
            .bold,
            .blinking,
        },
    });
    defer alloc.free(example);
    try expectEqualSlices(u8, "\u{001b}[2;1;5;34m\u{001b}[103mhello" ++ reset, example);
}
