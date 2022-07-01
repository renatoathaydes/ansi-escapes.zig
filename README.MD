# ANSI Escape Codes for Zig

Simple library to make it easy to print output on terminals supporting ANSI escape codes.

This allows printing colorized text and background, and adding simple text styles like underlined and even blinking.

## Usage

### Basic colors

Basic, one color text:

```zig
const std = @import("std");
const ansi = @import("ansi-escapes.zig");
const stdout = std.io.getStdOut().writer();

const yellow = ansi.Color.yellow.apply;

pub fn main() !void {
    const alloc = std.testing.allocator;
    const buffer = "Basic yellow text...\n";

    const formatted = try yellow(alloc, buffer);
    defer alloc.free(formatted);
    
    try stdout.writeAll(formatted);
}
```

The `apply` methods applies the color to the foreground (the text itself).

To colorize the background, use `applyBg`.

> All color types have `apply` and `applyBg` methods.

List of basic colors:

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

### Color8 (8-bit colors)

For a total of 256 different colors (with values from 0 to 255), use `Color8`:

```zig
const color = ansi.Color8{.value = 42};
const colorized = try color.apply(alloc, text);
```

Run the demo to display all `Color8` varieties on your terminal:

```bash
cd simple && zig build run
```

The result should look like this:

![All 8-bit colors displayed on terminal](docs/screenshot-color8.png)

### RGBColor (24-bit colors)

> Notice that not many terminals support 24-bit colors.

If you want even more colors, try `RGBColor`.

```zig
const color = ansi.RBGColor{.red = 42, .green = 43, .blue = 44};
const colorized = try color.applyBg(alloc, text);
```

### DisplayStyle

You can style text using `DisplayStyle`.

```zig
const bold = ansi.Displaystyle.bold;
const bold_text = try bold.apply(alloc, text);
```

List of styles:

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

### The `style` function

The `style` function allows setting multiple styles and a color simultaneously.

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

## Demos

To run the [demo CLI](src/example-simple-cli.zig):

```bash
zig build run
```
