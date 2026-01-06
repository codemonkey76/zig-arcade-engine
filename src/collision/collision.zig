const std = @import("std");
const types = @import("../mod.zig").types;

pub const CollisionBounds = union(enum) {
    circle: struct {
        radius: f32, // in normalized coordinates
    },
    rectangle: struct {
        width: f32, // in normalized coordinates
        height: f32, // in normalized coordinates
    },
    polygon: struct {
        vertices: []const types.Vec2, // relative to entity position, in normalized coordinates
    },
    none,
};

pub fn checkCollision(
    pos_a: types.Vec2,
    bounds_a: CollisionBounds,
    pos_b: types.Vec2,
    bounds_b: CollisionBounds,
) bool {
    return switch (bounds_a) {
        .none => false,
        .circle => |circle_a| switch (bounds_b) {
            .none => false,
            .circle => |circle_b| checkCircleCircle(pos_a, circle_a.radius, pos_b, circle_b.radius),
            .rectangle => |rect_b| checkCircleRect(pos_a, circle_a.radius, pos_b, rect_b),
            .polygon => |poly_b| checkCirclePolygon(pos_a, circle_a.radius, pos_b, poly_b.vertices),
        },
        .rectangle => |rect_a| switch (bounds_b) {
            .none => false,
            .circle => |circle_b| checkCircleRect(pos_b, circle_b.radius, pos_a, rect_a),
            .rectangle => |rect_b| checkRectRect(pos_a, rect_a, pos_b, rect_b),
            .polygon => |poly_b| checkRectPolygon(pos_a, rect_a, pos_b, poly_b.vertices),
        },
        .polygon => |poly_a| switch (bounds_b) {
            .none => false,
            .circle => |circle_b| checkCirclePolygon(pos_b, circle_b.radius, pos_a, poly_a.vertices),
            .rectangle => |rect_b| checkRectPolygon(pos_b, rect_b, pos_a, poly_a.vertices),
            .polygon => |poly_b| checkPolygonPolygon(pos_a, poly_a.vertices, pos_b, poly_b.vertices),
        },
    };
}

fn checkCircleCircle(pos_a: types.Vec2, radius_a: f32, pos_b: types.Vec2, radius_b: f32) bool {
    const dx = pos_a.x - pos_b.x;
    const dy = pos_a.y - pos_b.y;
    const distance_sq = dx * dx + dy * dy;
    const combined_radius = radius_a + radius_b;
    return distance_sq < (combined_radius * combined_radius);
}

fn checkRectRect(pos_a: types.Vec2, rect_a: anytype, pos_b: types.Vec2, rect_b: anytype) bool {
    const half_w_a = rect_a.width * 0.5;
    const half_h_a = rect_a.height * 0.5;
    const half_w_b = rect_b.width * 0.5;
    const half_h_b = rect_b.height * 0.5;

    return @abs(pos_a.x - pos_b.x) < (half_w_a + half_w_b) and
        @abs(pos_a.y - pos_b.y) < (half_h_a + half_h_b);
}

fn checkCircleRect(circle_pos: types.Vec2, radius: f32, rect_pos: types.Vec2, rect: anytype) bool {
    const half_w = rect.width * 0.5;
    const half_h = rect.height * 0.5;

    const closest_x = std.math.clamp(circle_pos.x, rect_pos.x - half_w, rect_pos.x + half_w);
    const closest_y = std.math.clamp(circle_pos.y, rect_pos.y - half_h, rect_pos.y + half_h);

    const dx = circle_pos.x - closest_x;
    const dy = circle_pos.y - closest_y;

    return (dx * dx + dy * dy) < (radius * radius);
}

fn checkCirclePolygon(circle_pos: types.Vec2, radius: f32, poly_pos: types.Vec2, vertices: []const types.Vec2) bool {
    // Check if circle center is inside polygon
    if (pointInPolygon(circle_pos, poly_pos, vertices)) return true;

    // Check if circle intersects any edge
    for (vertices, 0..) |_, i| {
        const next_i = (i + 1) % vertices.len;
        const v1 = types.Vec2{
            .x = poly_pos.x + vertices[i].x,
            .y = poly_pos.y + vertices[i].y,
        };
        const v2 = types.Vec2{
            .x = poly_pos.x + vertices[next_i].x,
            .y = poly_pos.y + vertices[next_i].y,
        };

        if (circleLineIntersect(circle_pos, radius, v1, v2)) return true;
    }

    return false;
}

fn checkRectPolygon(rect_pos: types.Vec2, rect: anytype, poly_pos: types.Vec2, vertices: []const types.Vec2) bool {
    // Convert rectangle to polygon vertices
    const half_w = rect.width * 0.5;
    const half_h = rect.height * 0.5;

    const rect_verts = [_]types.Vec2{
        .{ .x = -half_w, .y = -half_h },
        .{ .x = half_w, .y = -half_h },
        .{ .x = half_w, .y = half_h },
        .{ .x = -half_w, .y = half_h },
    };

    return checkPolygonPolygon(rect_pos, &rect_verts, poly_pos, vertices);
}

fn checkPolygonPolygon(pos_a: types.Vec2, verts_a: []const types.Vec2, pos_b: types.Vec2, verts_b: []const types.Vec2) bool {
    // Separating Axis Theorem (SAT)
    // Check axes from polygon A
    for (verts_a, 0..) |_, i| {
        const next_i = (i + 1) % verts_a.len;
        const edge = types.Vec2{
            .x = verts_a[next_i].x - verts_a[i].x,
            .y = verts_a[next_i].y - verts_a[i].y,
        };
        const axis = types.Vec2{ .x = -edge.y, .y = edge.x }; // perpendicular

        if (!overlapOnAxis(pos_a, verts_a, pos_b, verts_b, axis)) return false;
    }

    // Check axes from polygon B
    for (verts_b, 0..) |_, i| {
        const next_i = (i + 1) % verts_b.len;
        const edge = types.Vec2{
            .x = verts_b[next_i].x - verts_b[i].x,
            .y = verts_b[next_i].y - verts_b[i].y,
        };
        const axis = types.Vec2{ .x = -edge.y, .y = edge.x }; // perpendicular

        if (!overlapOnAxis(pos_a, verts_a, pos_b, verts_b, axis)) return false;
    }

    return true;
}

// Helper functions
fn pointInPolygon(point: types.Vec2, poly_pos: types.Vec2, vertices: []const types.Vec2) bool {
    var inside = false;

    for (vertices, 0..) |_, i| {
        const next_i = (i + 1) % vertices.len;
        const v1 = types.Vec2{
            .x = poly_pos.x + vertices[i].x,
            .y = poly_pos.y + vertices[i].y,
        };
        const v2 = types.Vec2{
            .x = poly_pos.x + vertices[next_i].x,
            .y = poly_pos.y + vertices[next_i].y,
        };

        if ((v1.y > point.y) != (v2.y > point.y)) {
            const slope = (point.y - v1.y) / (v2.y - v1.y);
            if (point.x < v1.x + slope * (v2.x - v1.x)) {
                inside = !inside;
            }
        }
    }

    return inside;
}

fn circleLineIntersect(circle_pos: types.Vec2, radius: f32, line_start: types.Vec2, line_end: types.Vec2) bool {
    // Find closest point on line segment to circle center
    const line_vec = types.Vec2{
        .x = line_end.x - line_start.x,
        .y = line_end.y - line_start.y,
    };
    const circle_vec = types.Vec2{
        .x = circle_pos.x - line_start.x,
        .y = circle_pos.y - line_start.y,
    };

    const line_len_sq = line_vec.x * line_vec.x + line_vec.y * line_vec.y;
    if (line_len_sq == 0) {
        // Line is a point
        const dx = circle_pos.x - line_start.x;
        const dy = circle_pos.y - line_start.y;
        return (dx * dx + dy * dy) < (radius * radius);
    }

    var t = (circle_vec.x * line_vec.x + circle_vec.y * line_vec.y) / line_len_sq;
    t = std.math.clamp(t, 0.0, 1.0);

    const closest = types.Vec2{
        .x = line_start.x + t * line_vec.x,
        .y = line_start.y + t * line_vec.y,
    };

    const dx = circle_pos.x - closest.x;
    const dy = circle_pos.y - closest.y;
    return (dx * dx + dy * dy) < (radius * radius);
}

fn overlapOnAxis(pos_a: types.Vec2, verts_a: []const types.Vec2, pos_b: types.Vec2, verts_b: []const types.Vec2, axis: types.Vec2) bool {
    const axis_len = @sqrt(axis.x * axis.x + axis.y * axis.y);
    if (axis_len == 0) return true;

    const norm_axis = types.Vec2{
        .x = axis.x / axis_len,
        .y = axis.y / axis_len,
    };

    // Project polygon A
    var min_a: f32 = std.math.floatMax(f32);
    var max_a: f32 = -std.math.floatMax(f32);
    for (verts_a) |v| {
        const world_v = types.Vec2{ .x = pos_a.x + v.x, .y = pos_a.y + v.y };
        const projection = world_v.x * norm_axis.x + world_v.y * norm_axis.y;
        min_a = @min(min_a, projection);
        max_a = @max(max_a, projection);
    }

    // Project polygon B
    var min_b: f32 = std.math.floatMax(f32);
    var max_b: f32 = -std.math.floatMax(f32);
    for (verts_b) |v| {
        const world_v = types.Vec2{ .x = pos_b.x + v.x, .y = pos_b.y + v.y };
        const projection = world_v.x * norm_axis.x + world_v.y * norm_axis.y;
        min_b = @min(min_b, projection);
        max_b = @max(max_b, projection);
    }

    // Check overlap
    return !(max_a < min_b or max_b < min_a);
}
