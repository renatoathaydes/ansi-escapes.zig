const std = @import("std");
const ansi = @import("ansi-escapes");

const red = ansi.Color.red.apply;

pub fn main() !void {
    const alloc = std.testing.allocator;
    const hello = try red(alloc, "Hello in RED!");
    defer alloc.free(hello);
    std.debug.print("{s}\n", .{hello});

    const rgb = ansi.RGBColor{ .green = 255 };
    const bye = try rgb.apply(alloc, "Bye in RGB Color (does not work in all terminals)!");
    defer alloc.free(bye);
    std.debug.print("{s}\n", .{bye});
}
