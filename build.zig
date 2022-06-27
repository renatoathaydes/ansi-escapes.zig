const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("ansi-escapes.zig", "src/ansi-escapes.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/ansi-escapes.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    _ = b.step("demo", "Build a simple demo");
    const demo = b.addExecutable("demo", "src/example-simple-cli.zig");
    demo.setBuildMode(mode);
    demo.install();

    const run_cmd = demo.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the simple demo");
    run_step.dependOn(&run_cmd.step);
}
