const std = @import("std");

const expectEqual = std.testing.expectEqual;

pub const reset = "\u{001b}[m";

pub fn codeToString(code: u8, buffer: []u8) std.fmt.BufPrintError![]u8 {
    return std.fmt.bufPrint(buffer, "{d}", .{code});
}

test "codeToString" {
    var buf: [3]u8 = undefined;

    try std.testing.expectEqualSlices(u8, "0", try codeToString(0, &buf));
    try std.testing.expectEqualSlices(u8, "48", try codeToString(48, &buf));
    try std.testing.expectEqualSlices(u8, "109", try codeToString(109, &buf));
    try std.testing.expectEqualSlices(u8, "255", try codeToString(255, &buf));
    try std.testing.expectEqualSlices(u8, "2", try codeToString(2, &buf));
}

pub fn digitLen(code: u8) usize {
    if (code < 10) {
        return 1;
    } else if (code < 100) {
        return 2;
    } else {
        return 3;
    }
}

test "digitLen" {
    try expectEqual(@as(usize, 1), digitLen(0));
    try expectEqual(@as(usize, 1), digitLen(1));
    try expectEqual(@as(usize, 2), digitLen(10));
    try expectEqual(@as(usize, 2), digitLen(99));
    try expectEqual(@as(usize, 3), digitLen(100));
    try expectEqual(@as(usize, 3), digitLen(255));
}
