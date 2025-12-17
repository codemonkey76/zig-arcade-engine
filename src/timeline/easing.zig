const std = @import("std");

/// Standard easing functions for smooth animations
/// All functions take t in range [0, 1] and return eased value in [0, 1]
pub fn linear(t: f32) f32 {
    return t;
}

pub fn easeInQuad(t: f32) f32 {
    return t * t;
}

pub fn easeOutQuad(t: f32) f32 {
    return t * (2.0 - t);
}

pub fn easeInOutQuad(t: f32) f32 {
    if (t < 0.5) {
        return 2.0 * t * t;
    } else {
        const t2 = t - 1.0;
        return 1.0 - 2.0 * t2 * t2;
    }
}

pub fn easeInCubic(t: f32) f32 {
    return t * t * t;
}

pub fn easeOutCubic(t: f32) f32 {
    const t2 = t - 1.0;
    return 1.0 + t2 * t2 * t2;
}

pub fn easeInOutCubic(t: f32) f32 {
    if (t < 0.5) {
        return 4.0 * t * t * t;
    } else {
        const t2 = t - 1.0;
        return 1.0 + 4.0 * t2 * t2 * t2;
    }
}

pub fn easeInSine(t: f32) f32 {
    return 1.0 - @cos(t * std.math.pi / 2.0);
}

pub fn easeOutSine(t: f32) f32 {
    return @sin(t * std.math.pi / 2.0);
}

pub fn easeInOutSine(t: f32) f32 {
    return -((@cos(std.math.pi * t) - 1.0) / 2.0);
}

pub fn easeInExpo(t: f32) f32 {
    if (t == 0.0) return 0.0;
    return std.math.pow(f32, 2.0, 10.0 * (t - 1.0));
}

pub fn easeOutExpo(t: f32) f32 {
    if (t == 1.0) return 1.0;
    return 1.0 - std.math.pow(f32, 2.0, -10.0 * t);
}

pub fn easeInOutExpo(t: f32) f32 {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;

    if (t < 0.5) {
        return std.math.pow(f32, 2.0, 20.0 * t - 10.0) / 2.0;
    } else {
        return (2.0 - std.math.pow(f32, 2.0, -20.0 * t + 10.0)) / 2.0;
    }
}

/// Bounce effect at the end
pub fn easeOutBounce(t: f32) f32 {
    const n1: f32 = 7.5625;
    const d1: f32 = 2.75;

    if (t < 1.0 / d1) {
        return n1 * t * t;
    } else if (t < 2.0 / d1) {
        const t2 = t - (1.5 / d1);
        return n1 * t2 * t2 + 0.75;
    } else if (t < 2.5 / d1) {
        const t2 = t - (2.25 / d1);
        return n1 * t2 * t2 + 0.9375;
    } else {
        const t2 = t - (2.625 / d1);
        return n1 * t2 * t2 + 0.984375;
    }
}

/// Elastic effect (spring-like)
pub fn easeOutElastic(t: f32) f32 {
    const c4 = (2.0 * std.math.pi) / 3.0;

    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;

    return std.math.pow(f32, 2.0, -10.0 * t) * @sin((t * 10.0 - 0.75) * c4) + 1.0;
}

test "easing functions output range" {
    const testing = std.testing;

    const functions = .{
        linear,
        easeInQuad,
        easeOutQuad,
        easeInOutQuad,
        easeInCubic,
        easeOutCubic,
        easeInOutCubic,
    };

    inline for (functions) |func| {
        // Test at boundaries
        try testing.expectApproxEqAbs(@as(f32, 0.0), func(0.0), 0.001);
        try testing.expectApproxEqAbs(@as(f32, 1.0), func(1.0), 0.001);

        // Test midpoint is in valid range
        const mid = func(0.5);
        try testing.expect(mid >= 0.0 and mid <= 1.0);
    }
}

test "linear is identity" {
    const testing = std.testing;

    try testing.expectEqual(@as(f32, 0.0), linear(0.0));
    try testing.expectEqual(@as(f32, 0.25), linear(0.25));
    try testing.expectEqual(@as(f32, 0.5), linear(0.5));
    try testing.expectEqual(@as(f32, 0.75), linear(0.75));
    try testing.expectEqual(@as(f32, 1.0), linear(1.0));
}
