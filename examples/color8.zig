const std = @import("std");
const ansi = @import("ansi-escapes");

const Color8 = ansi.Color8;

/// Center the digit string within up to 5 slots.
fn center(text: u8, out: *[5]u8) !void {
    const left_pad = if (text < 10) @as(usize, 3) else if (text < 100) @as(usize, 2) else @as(usize, 1);
    for (out) |*b| {
        b.* = ' ';
    }
    _ = try std.fmt.bufPrint(out[left_pad..], "{d}", .{text});
}

pub fn main() !void {
    const stdout = std.io.getStdOut();

    const alloc = init: {
        var memory: [512]u8 = undefined;
        var allocator = std.heap.FixedBufferAllocator.init(&memory);
        break :init allocator.allocator();
    };

    var is_bg: bool = false;
    const args = try std.process.argsAlloc(alloc);
    defer alloc.free(args);
    for (args[1..]) |arg| {
        is_bg = std.mem.eql(u8, arg, "bg");
    }

    if (!is_bg) {
        try stdout.writeAll("Run with the 'bg' argument to color the background.\n");
    }

    var text: [5]u8 = undefined;
    var i: u8 = 0;
    while (i < 256) : (i += 1) {
        if (i != 0 and i % 16 == 0) {
            try stdout.writeAll("\n");
        }
        try center(i, &text);
        const c8 = Color8{ .value = i };
        const square = try (if (is_bg) c8.applyBg(alloc, text[0..]) else c8.apply(alloc, text[0..]));
        defer alloc.free(square);
        try stdout.writeAll(square);
        if (i == 255) break; // avoid overflow
    }
    try stdout.writeAll("\n");
}
