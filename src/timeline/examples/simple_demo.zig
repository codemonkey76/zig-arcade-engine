//
// This example shows how to use the timeline system to create a simple demo
// with entities moving and shooting

const std = @import("std");
const timeline_mod = @import("../mod.zig");
const ActionBase = timeline_mod.ActionBase;
const Timeline = timeline_mod.Timeline;
const EntityRef = timeline_mod.EntityRef;
const ScriptBuilder = timeline_mod.ScriptBuilder;

// ============================================================================
// 1. Define your game's entity types
// ============================================================================

const EntityType = enum {
    player,
    enemy,
    projectile,
};

const Vec2 = struct { x: f32, y: f32 };

const Entity = struct {
    id: u32,
    entity_type: EntityType,
    position: Vec2,
    active: bool = true,
};

// ============================================================================
// 2. Define your game's actions
// ============================================================================

const ActionData = union(enum) {
    spawn: struct {
        entity_type: EntityType,
        position: Vec2,
    },
    move_to: struct {
        target: EntityRef(u32, EntityType),
        position: Vec2,
        speed: f32,
    },
    shoot: struct {
        shooter: EntityRef(u32, EntityType),
        target: EntityRef(u32, EntityType),
    },
    despawn: struct {
        target: EntityRef(u32, EntityType),
    },
};

const GameAction = struct {
    base: ActionBase,
    data: ActionData,
};

// ============================================================================
// 3. Create an executor that handles your actions
// ============================================================================

const ActionExecutor = struct {
    entities: std.ArrayList(Entity),
    next_id: u32 = 1,

    pub fn init(allocator: std.mem.Allocator) ActionExecutor {
        return .{
            .entities = std.ArrayList(Entity).init(allocator),
        };
    }

    pub fn start(self: *ActionExecutor, action: GameAction) !void {
        switch (action.data) {
            .spawn => |spawn| {
                try self.entities.append(.{
                    .id = self.next_id,
                    .entity_type = spawn.entity_type,
                    .position = spawn.position,
                });
                self.next_id += 1;
            },
            else => {},
        }
    }

    pub fn update(self: *ActionExecutor, action: GameAction, progress: f32) !void {
        switch (action.data) {
            .move_to => |move| {
                if (self.findEntity(move.target)) |entity| {
                    // Lerp toward target position
                    const start_x = entity.position.x;
                    const start_y = entity.position.y;
                    entity.position.x = start_x + (move.position.x - start_x) * progress;
                    entity.position.y = start_y + (move.position.y - start_y) * progress;
                }
            },
            .shoot => {
                // Fire projectile (simplified)
                std.debug.print("Bang! (progress: {d:.2})\n", .{progress});
            },
            .despawn => |despawn| {
                if (self.findEntity(despawn.target)) |entity| {
                    entity.active = false;
                }
            },
            else => {},
        }
    }

    pub fn reset(self: *ActionExecutor) !void {
        self.entities.clearRetainingCapacity();
        self.next_id = 1;
    }

    fn findEntity(self: *ActionExecutor, ref: EntityRef(u32, EntityType)) ?*Entity {
        return switch (ref) {
            .id => |id| {
                for (self.entities.items) |*e| {
                    if (e.id == id and e.active) return e;
                }
                return null;
            },
            .tag => |tag| {
                for (self.entities.items) |*e| {
                    if (e.entity_type == tag and e.active) return e;
                }
                return null;
            },
        };
    }

    pub fn deinit(self: *ActionExecutor) void {
        self.entities.deinit();
    }
};

// ============================================================================
// 4. Build your timeline script
// ============================================================================

fn createDemoScript(allocator: std.mem.Allocator) ![]const GameAction {
    var builder = ScriptBuilder(ActionData).init(allocator);
    defer builder.deinit();

    // Spawn player
    try builder.add(0.0, 0.1, .{
        .spawn = .{
            .entity_type = .player,
            .position = .{ .x = 0.5, .y = 0.9 },
        },
    });

    // Spawn enemy
    try builder.add(0.5, 0.1, .{
        .spawn = .{
            .entity_type = .enemy,
            .position = .{ .x = 0.5, .y = 0.1 },
        },
    });

    // Player moves right
    try builder.add(1.0, 2.0, .{
        .move_to = .{
            .target = .{ .tag = .player },
            .position = .{ .x = 0.8, .y = 0.9 },
            .speed = 0.15,
        },
    });

    // Player shoots enemy
    try builder.add(3.0, 0.1, .{
        .shoot = .{
            .shooter = .{ .tag = .player },
            .target = .{ .id = 2 },
        },
    });

    // Despawn enemy
    try builder.add(3.5, 0.1, .{
        .despawn = .{
            .target = .{ .id = 2 },
        },
    });

    const actions = try builder.build();

    // Convert to GameAction format
    var game_actions = try allocator.alloc(GameAction, actions.len);
    for (actions, 0..) |action, i| {
        game_actions[i] = .{
            .base = action.base,
            .data = action.data,
        };
    }
    allocator.free(actions);

    return game_actions;
}

// ============================================================================
// 5. Use the timeline
// ============================================================================

pub fn runDemo(allocator: std.mem.Allocator) !void {
    const DemoTimeline = Timeline(GameAction, ActionExecutor);

    const script = try createDemoScript(allocator);
    var executor = ActionExecutor.init(allocator);
    defer executor.deinit();

    var demo = try DemoTimeline.init(
        allocator,
        script,
        executor,
        .{ .loop = true },
    );
    defer demo.deinit();

    std.debug.print("Demo timeline duration: {d:.2}s\n", .{demo.getTotalDuration()});

    // Simulate a few updates
    var time: f32 = 0.0;
    while (time < 5.0) : (time += 0.5) {
        try demo.update(0.5);
        std.debug.print("Time: {d:.2}s, Entities: {}\n", .{ demo.elapsed_time, demo.executor.entities.items.len });
    }
}

test "simple demo runs" {
    const testing = std.testing;
    try runDemo(testing.allocator);
}
