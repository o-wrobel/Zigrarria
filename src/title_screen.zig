const std = @import("std");
const rl = @import("raylib");
const rgui = @import("raygui");

var WINDOW_WIDTH: i32 = 1400;
var WINDOW_HEIGHT: i32 = 800;

pub fn draw() bool {
	const rect: rl.Rectangle = .init(550, 320+100, 300, 80);

	rl.beginDrawing();
	defer rl.endDrawing();

	rl.clearBackground(.sky_blue);
	rl.drawText(
		"Terraria",
		@as(i32, @divFloor(WINDOW_WIDTH, 2)) - 170,
		@as(i32, @divFloor(WINDOW_HEIGHT, 2)) - 80,
		80,
		.white
	);
	return rgui.button(rect, "Play");
}
