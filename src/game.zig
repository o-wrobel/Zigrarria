const std = @import("std");

const rl = @import("raylib");
const znoise = @import("znoise");

const level = @import("level.zig");
const Grid = level.Grid;

const camera_move_speed = 660;

const State = struct {
	grid: level.Grid,
	camera: rl.Camera2D,

	pub fn init(allocator: std.mem.Allocator)  !State {
		const config: level.WorldConfig = .{
			.width = 200,
			.height = 80
		};

		return .{
			.grid = try level.getRandomLevel(config, allocator),
			.camera = .{
				.offset = .init(0, 0),
				.rotation = 0,
				.target = .init(0, 0),
				.zoom = 1
			}
		};
	}
};

fn getMouseGridPosition(grid: Grid, camera: rl.Camera2D) rl.Vector2 {
	return level.getGridPosition(
		grid,
		rl.getMousePosition(),
		camera
	).clamp(.init(0, 0), .init(@floatFromInt(grid.width-1), @floatFromInt(grid.height-1)));
}

fn printInfo(state: *const State) !void {
	const mouse_grid_position = level.getGridPosition(
		state.grid,
		rl.getMousePosition(),
		state.camera
	).clamp(.init(0, 0), .init(63, 63));
	var buffer: [128]u8 = undefined;
	const string = try std.fmt.bufPrintZ(
		&buffer,
		"{}, {}, {s}\n",
		.{
			mouse_grid_position.x,
			mouse_grid_position.y,
			@tagName(
				state.grid.tileAt(
					@intFromFloat(mouse_grid_position.x),
					@intFromFloat(mouse_grid_position.y)
				) catch .none
			)
		}
	);
	rl.drawText(
		string,
		10,
		280,
		18,
		.white
	);
}

fn handleCameraMovement(camera: *rl.Camera2D, delta_time: f32) void {
	if (rl.isKeyDown(.a)) camera.target.x -= camera_move_speed*delta_time;
	if (rl.isKeyDown(.w)) camera.target.y -= camera_move_speed*delta_time;
	if (rl.isKeyDown(.d)) camera.target.x += camera_move_speed*delta_time;
	if (rl.isKeyDown(.s)) camera.target.y += camera_move_speed*delta_time;
}

fn handleTilePlacing(state: *State) !void {
	if (rl.isMouseButtonPressed(.left)) {
		const mouse_grid_position = getMouseGridPosition(state.grid, state.camera);
		const x: u64 = @intFromFloat(mouse_grid_position.x);
		const y: u64 = @intFromFloat(mouse_grid_position.y);
		try state.grid.placeTile(x, y, .dirt);
	}
}

pub fn runGameLoop(allocator: std.mem.Allocator) !void {
	var seed: u64 = 0;
	try std.posix.getrandom(std.mem.asBytes(&seed));

	var state = try State.init(allocator);
	const spritesheet = try rl.loadTexture("assets/dirt.png");
	try state.grid.placeTile(0, 0, .dirt);
	try state.grid.placeTile(2, 1, .dirt);

	while (!rl.windowShouldClose()) {
		const delta_time = rl.getFrameTime();

		try handleTilePlacing(&state);
		handleCameraMovement(&state.camera, delta_time);

		// Drawing
		rl.beginDrawing();
		defer rl.endDrawing();

		rl.clearBackground(.sky_blue);
		rl.beginMode2D(state.camera);

		try level.drawGrid(&state.grid, spritesheet);
		rl.endMode2D();

		// Fixed Drawing
		try printInfo(&state);
	}
}

pub fn run(window_width: i32, window_height: i32) !void {
	rl.initWindow(window_width, window_height, "Hello, world!");
	defer rl.closeWindow();

	var debug_allocator = std.heap.DebugAllocator(.{}).init;
	const allocator = debug_allocator.allocator();

	if (!rl.isWindowReady()) {return error.InitWindow;}
	try runGameLoop(allocator);
}
