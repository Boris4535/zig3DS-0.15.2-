// src/3ds/c.zig
pub const c = @cImport({
    // 1. Hardware Definitions
    @cDefine("_3DS", "1");
    @cDefine("__arm__", "1");
    @cDefine("__ARM_32BIT_STATE", "1");

    // 2. Type Fixes (Critical)
    
    // This satisfies the strict type checking in generated inline functions.
    @cDefine("true", "((_Bool)1)");
    @cDefine("false", "((_Bool)0)");

    // 3. Includes
    @cInclude("stdio.h");
    @cInclude("3ds.h");
});
