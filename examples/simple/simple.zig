const std = @import("std");
const ansi = @import("ansi-escapes");
const stdout = std.io.getStdOut().writer();

const yellow = ansi.Color.yellow.apply;
const magenta_bg = ansi.Color.magenta.applyBg;

pub fn main() !void {
    const alloc = std.testing.allocator;
    const buffer = "Basic yellow text...\n";

    const formatted = try yellow(alloc, buffer);
    defer alloc.free(formatted);
    try stdout.writeAll(formatted);
    
    const buffer2 = "Magenta background!!!\n";
    const formatted2 = try magenta_bg(alloc, buffer2);
    defer alloc.free(formatted2);
    try stdout.writeAll(formatted2);
}
