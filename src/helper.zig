const std = @import("std");
const rl = @import("raylib");

pub fn getCameraBounds(camera: rl.Camera2D) struct{rl.Vector2, rl.Vector2} {
	const top_left = rl.getScreenToWorld2D(.init(0, 0), camera);
	const bottom_right = rl.getScreenToWorld2D(
		.init(
			@floatFromInt(rl.getScreenWidth()),
			@floatFromInt(rl.getScreenHeight())
		),
		camera
	);

	// std.debug.print("{}, {} ||| {}, {}\n", .{top_left.x, top_left.y, bottom_right.x, bottom_right.y});
	return .{top_left, bottom_right};
}
