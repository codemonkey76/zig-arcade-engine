const std = @import("std");
const rl = @import("raylib");

pub fn AudioManager(comptime SoundId: type) type {
    return struct {
        allocator: std.mem.Allocator,
        asset_root: []const u8,
        sounds: std.AutoHashMap(SoundId, rl.Sound),
        music: std.StringHashMap(rl.Music),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, asset_root: []const u8) !Self {
            rl.initAudioDevice();
            return .{
                .allocator = allocator,
                .asset_root = asset_root,
                .sounds = std.AutoHashMap(SoundId, rl.Sound).init(allocator),
                .music = std.StringHashMap(rl.Music).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.sounds.iterator();
            while (it.next()) |entry| {
                rl.unloadSound(entry.value_ptr.*);
            }
            self.sounds.deinit();

            var music_it = self.music.iterator();
            while (music_it.next()) |entry| {
                rl.unloadMusicStream(entry.value_ptr.*);
                self.allocator.free(entry.key_ptr.*);
            }
            self.music.deinit();

            rl.closeAudioDevice();
        }

        pub fn loadSound(self: *Self, id: SoundId, filename: []const u8) !void {
            if (self.sounds.contains(id)) {
                return;
            }

            const full_path = try std.fs.path.join(self.allocator, &.{ self.asset_root, filename });
            defer self.allocator.free(full_path);

            const path_z = try self.allocator.dupeZ(u8, full_path);
            defer self.allocator.free(path_z);

            const sound = try rl.loadSound(path_z);

            try self.sounds.put(id, sound);
        }

        pub fn playSound(self: *Self, id: anytype) void {
            const sound_id: SoundId = id;
            if (self.sounds.get(sound_id)) |sound| {
                rl.playSound(sound);
            }
        }

        pub fn stopSound(self: *Self, id: SoundId) void {
            if (self.sounds.get(id)) |sound| {
                rl.stopSound(sound);
            }
        }

        pub fn setSoundVolume(self: *Self, id: SoundId, volume: f32) void {
            if (self.sounds.get(id)) |sound| {
                rl.setSoundVolume(sound, volume);
            }
        }

        pub fn isSoundPlaying(self: *Self, id: SoundId) bool {
            if (self.sounds.get(id)) |sound| {
                return rl.isSoundPlaying(sound);
            }
            return false;
        }

        pub fn loadMusic(self: *Self, filename: []const u8) !void {
            if (self.music.contains(filename)) {
                return;
            }

            const full_path = try std.fs.path.join(self.allocator, &.{ self.asset_root, filename });
            defer self.allocator.free(full_path);

            const path_z = try self.allocator.dupeZ(u8, full_path);
            defer self.allocator.free(path_z);

            const music = try rl.loadMusicStream(path_z);

            const key = try self.allocator.dupe(u8, filename);
            errdefer self.allocator.free(key);

            try self.music.put(key, music);
        }

        pub fn playMusic(self: *Self, filename: []const u8) void {
            if (self.music.get(filename)) |music| {
                rl.playMusicStream(music);
            }
        }

        pub fn updateMusic(self: *Self, filename: []const u8) void {
            if (self.music.get(filename)) |music| {
                rl.updateMusicStream(music);
            }
        }

        pub fn setMasterVolume(volume: f32) void {
            rl.setMasterVolume(volume);
        }
    };
}
