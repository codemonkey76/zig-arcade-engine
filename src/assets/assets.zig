const std = @import("std");
const rl = @import("raylib");
const arcade_lib = @import("arcade_lib");
const PathDefinition = arcade_lib.PathDefinition;
const Texture = @import("../graphics/texture.zig").Texture;
const Path = @import("../math/path.zig").Path;
const AssetCache = @import("asset_cache.zig").AssetCache;
const Font = @import("../graphics/font.zig").Font;
const Sound = @import("../assets/sound.zig").Sound;

pub fn AssetManager(
    comptime TextureAsset: type,
    comptime FontAsset: type,
    comptime PathAsset: type,
    comptime SoundAsset: type,
) type {
    comptime {
        // Check texture Asset has the required methods
        if (!@hasDecl(TextureAsset, "filename")) {
            @compileError("TextureAsset must have a 'pub fn filename(self: TextureAsset) []const u8' method");
        }
        if (!@hasDecl(TextureAsset, "transparentColor")) {
            @compileError("TextureAsset must have a 'pub fn transparentColor(self: TextureAsset) ?rl.Color' method");
        }

        // Check Font Asset has the required methods
        if (!@hasDecl(FontAsset, "filename")) {
            @compileError("FontAsset must have a 'pub fn filename(self: FontAsset) []const u8' method");
        }
        if (!@hasDecl(FontAsset, "size")) {
            @compileError("FontAsset must have a 'pub fn size(self: FontAsset) ?i32' method");
        }

        // Check PathAsset has required methods
        if (!@hasDecl(PathAsset, "filename")) {
            @compileError("PathAsset must have a 'pub fn filename(self: PathAsset) []const u8' method");
        }

        // Check SoundAsset has required methods
        if (!@hasDecl(SoundAsset, "filename")) {
            @compileError("SoundAsset must have a 'pub fn filename(self: PathAsset) []const u8' method");
        }
    }

    return struct {
        allocator: std.mem.Allocator,
        asset_root: []const u8,
        textures: TextureCache,
        fonts: FontCache,
        paths: PathCache,
        sounds: SoundCache,

        const Self = @This();

        const TextureCache = AssetCache(TextureAsset, Texture, ?rl.Color, Texture.load, Texture.unload);
        const FontCache = AssetCache(FontAsset, Font, ?i32, Font.load, Font.unload);
        const PathCache = AssetCache(PathAsset, Path, void, Path.load, Path.unload);
        const SoundCache = AssetCache(SoundAsset, Sound, void, Sound.load, Sound.unload);

        pub fn init(allocator: std.mem.Allocator, asset_root: []const u8) !Self {
            rl.initAudioDevice();
            return .{
                .allocator = allocator,
                .asset_root = asset_root,
                .textures = TextureCache.init(allocator),
                .fonts = FontCache.init(allocator),
                .paths = PathCache.init(allocator),
                .sounds = SoundCache.init(allocator),
            };
        }

        // Textures
        pub fn loadTexture(self: *Self, asset: TextureAsset) !Texture {
            return self.textures.load(
                self.allocator,
                self.asset_root,
                asset,
                asset.filename(),
                asset.transparentColor(),
            );
        }

        pub fn getTexture(self: *Self, asset: TextureAsset) ?Texture {
            return self.textures.get(asset);
        }

        pub fn unloadTexture(self: *Self, asset: TextureAsset) void {
            self.textures.unload(asset);
        }

        // Fonts
        pub fn loadFont(self: *Self, asset: FontAsset) !Font {
            return self.fonts.load(
                self.allocator,
                self.asset_root,
                asset,
                asset.filename(),
                asset.size(),
            );
        }

        pub fn getFont(self: *Self, asset: FontAsset) ?Font {
            return self.fonts.get(asset);
        }

        pub fn unloadFont(self: *Self, asset: FontAsset) void {
            self.fonts.unload(asset);
        }

        // Paths
        pub fn loadPaths(self: *Self, asset: PathAsset) !Path {
            return self.paths.load(
                self.allocator,
                self.asset_root,
                asset,
                asset.filename(),
                {},
            );
        }

        pub fn getPath(self: *Self, asset: PathAsset) ?Path {
            return self.paths.get(asset);
        }

        pub fn unloadPath(self: *Self, asset: PathAsset) void {
            self.paths.unload(asset);
        }

        // Sounds
        pub fn loadSound(self: *Self, asset: SoundAsset) !Sound {
            return self.sounds.load(
                self.allocator,
                self.asset_root,
                asset,
                asset.filename(),
                {},
            );
        }

        pub fn getSound(self: *Self, asset: SoundAsset) ?Sound {
            return self.sounds.get(asset);
        }

        pub fn unloadSound(self: *Self, asset: SoundAsset) void {
            self.sounds.unload(asset);
        }

        pub fn playSound(self: *Self, asset: SoundAsset) void {
            if (self.getSound(asset)) |sound| {
                rl.playSound(sound.handle);
            }
        }

        pub fn deinit(self: *Self) void {
            self.textures.deinit();
            self.fonts.deinit();
            self.paths.deinit();
            self.sounds.deinit();
        }
    };
}
