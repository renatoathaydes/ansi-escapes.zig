const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    _ = b.step("demo", "Build a simple demo");
    const demo = b.addExecutable("simple", "simple.zig");
    demo.setBuildMode(mode);
    demo.addPackagePath("ansi-escapes", "../../src/ansi-escapes.zig");
    demo.install();

    const run_cmd = demo.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the simple demo");
    run_step.dependOn(&run_cmd.step);
}
