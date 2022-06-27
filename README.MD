# ANSI Escape Codes for Zig

Simple library to make it easy to print output on terminals supporting ANSI escape codes.

This allows printing colorized text and background, and adding simple text styles like underlined and even blinking.

## Usage

Basic, one color text:

```zig
const std = @import("std");
const ansi = @import("ansi-escapes.zig");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const alloc = std.testing.allocator;
    const buffer = "Basic yellow text...\n";

    const formatted = try ansi.Color.yellow.format(alloc, buffer);
    defer alloc.free(formatted);
    
    try stdout.writeAll(formatted);
}
```

Set fg (foreground color), bg (background color) and some styles:

```zig
const std = @import("std");
const ansi = @import("ansi-escapes.zig");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const alloc = std.testing.allocator;
    const buffer = "Style this!\n";

    const styled_text = try ansi.style(alloc, buffer[0..], .{
        .fg = .red,
        .bg = .white,
        .styles = &.{ .italic, .bold },
    });
    defer alloc.free(styled_text);

    try stdout.writeAll(styled_text);
}
```

## List of colors

```
black
red
green
yellow
blue
magenta
cyan
white
```

Colors starting with `b_` are _bright_ colors.

Example: `b_blue` is bright blue.

## List of styles:

```
bold
faint
italic
underline
blinking
fast_blinking
reverse
hidden
```

## Demo

To run the [demo CLI](src/example-simple-cli.zig):

```bash
zig build run
```
