const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var simple = addExe(b, mode, "simple", "simple.zig");
    var run_simple = b.step("simple", "Run the simple demo");
    run_simple.dependOn(&simple.step);

    var color8 = addExe(b, mode, "color8", "color8.zig");
    var run_color8 = b.step("color8", "Run the color8 demo");
    run_color8.dependOn(&color8.step);

    var cli = addExe(b, mode, "cli", "cli.zig");
    var run_cli = b.step("cli", "Run the cli demo");
    run_cli.dependOn(&cli.step);
}

fn addExe(b: *std.build.Builder, mode: std.builtin.Mode, name: []const u8, path: []const u8) *std.build.RunStep {
    const exe = b.addExecutable(name, path);
    exe.setBuildMode(mode);
    exe.addPackagePath("ansi-escapes", "../src/ansi-escapes.zig");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    return run_cmd;
}
