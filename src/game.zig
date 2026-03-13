const rl = @import("raylib");
const znoise = @import("znoise");

pub fn run(window_width: i32, window_height: i32) !void {
	rl.initWindow(window_width, window_height, "Zigrarria");
	defer rl.closeWindow();

	while(!rl.windowShouldClose()) {
		rl.beginDrawing();
		defer rl.endDrawing();
		rl.clearBackground(.black);
	}
}
