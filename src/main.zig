const c = @import("3ds/c.zig").c;
export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    c.gfxInitDefault();
    defer c.gfxExit();

    _ = c.consoleInit(c.GFX_TOP, null);

    _ = c.printf("\x1b[10;10HPROGRAM TITLE HERE!!!!");
    _ = c.printf("\x1b[12;10HZig : 0.15.2");
    _ = c.printf("\x1b[14;10HSystem: IT WORKS");

    while (c.aptMainLoop()) {
        c.hidScanInput();
        const kDown = c.hidKeysDown();

        if ((kDown & c.KEY_START) != 0) break; //press start to exit

        c.gspWaitForVBlank();

        c.gfxSwapBuffers();
    }
}
