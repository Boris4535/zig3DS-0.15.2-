const std = @import("std");

pub fn build(b: *std.Build) void {
    const devkitpro = std.process.getEnvVarOwned(b.allocator, "DEVKITPRO") catch "/opt/devkitpro";

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.mpcore },
        .cpu_features_add = std.Target.arm.featureSet(&.{.vfp2}),
    });

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });

    const game_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    game_mod.addCMacro("_3DS", "1");
    game_mod.addCMacro("__arm__", "1");
    game_mod.addCMacro("__ARM_32BIT_STATE", "1");

    game_mod.addIncludePath(.{ .cwd_relative = b.fmt("{s}/libctru/include", .{devkitpro}) });
    game_mod.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/3ds/include", .{devkitpro}) });

    const obj = b.addObject(.{
        .name = "[yourprogramhere]",
        .root_module = game_mod,
    });

    obj.setLibCFile(b.path("libc.txt"));

    //linker is built manually to prevent errors of different nature, and idk how to do in any other way

    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/bin" });

    var link_args = std.ArrayListUnmanaged([]const u8){};
    defer link_args.deinit(b.allocator);

    link_args.append(b.allocator, b.fmt("{s}/devkitARM/bin/arm-none-eabi-gcc", .{devkitpro})) catch @panic("OOM");

    // Flags
    link_args.appendSlice(b.allocator, &.{
        "-g",
        "-march=armv6k",
        "-mtune=mpcore",
        "-mfloat-abi=hard",
        "-mtp=soft",
        "-Wl,-Map,zig-out/bin/game.map",
    }) catch @panic("OOM");

    link_args.append(b.allocator, b.fmt("-specs={s}/devkitARM/arm-none-eabi/lib/3dsx.specs", .{devkitpro})) catch @panic("OOM");

    link_args.appendSlice(b.allocator, &.{ "-o", "zig-out/bin/game.elf" }) catch @panic("OOM");

    const elf_cmd = b.addSystemCommand(link_args.items);

    elf_cmd.addFileArg(obj.getEmittedBin());

    // IMPORTANT: Add Libraries AFTER the object file (Order matters!)
    elf_cmd.addArgs(&.{
        b.fmt("-L{s}/libctru/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/3ds/lib", .{devkitpro}),
        "-lctru",
        "-lm",
    });

    // Dependencies
    elf_cmd.step.dependOn(&mkdir_cmd.step);

    // 3DSX Conversion
    const dsx_cmd = b.addSystemCommand(&.{ b.fmt("{s}/tools/bin/3dsxtool", .{devkitpro}), "zig-out/bin/game.elf", "zig-out/bin/game.3dsx" });
    dsx_cmd.step.dependOn(&elf_cmd.step);
    b.getInstallStep().dependOn(&dsx_cmd.step);

    // [OPTIONAL] STREAMING DIRECTLY TO YOUR 2DS OR 3DS. But, for larger programs its best to send the file over and THEN run it.
    //or use citra...
    const deploy_cmd = b.addSystemCommand(&.{
        b.fmt("{s}/tools/bin/3dslink", .{devkitpro}),
        "zig-out/bin/game.3dsx",
        "-a",
        "[your 2ds IP here]", // can be found in the homebrew menu pressing "y"
    });
    deploy_cmd.step.dependOn(&dsx_cmd.step);
    b.step("deploy", "Sending...").dependOn(&deploy_cmd.step);
}
