pub const Config = struct {
    title: [:0]const u8 = "Game",
    width: u32 = 1280,
    height: u32 = 720,
    target_fps: u32 = 60,

    // Virtual resolution for game viewport
    virtual_width: u32 = 224,
    virtual_height: u32 = 288,
    ssaa_scale: u32 = 2,
    dpi_scale: u32 = 1,

    resizable: bool = true,
    fullscreen: bool = false,

    asset_root: []const u8 = "assets",

    audio_enabled: bool = true,
    master_volume: f32 = 1.0,
};
