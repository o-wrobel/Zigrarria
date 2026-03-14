const std = @import("std");

const rl = @import("raylib");
const rgui = @import("raygui");
const znoise = @import("znoise");

const title_screen = @import("title_screen.zig");
const level = @import("level.zig");
const Grid = level.Grid;

const camera_move_speed = 660;

var WINDOW_WIDTH: i32 = 1400;
var WINDOW_HEIGHT: i32 = 800;


pub const Config = struct {
	window_width: i32,
	window_height: i32,
};

const GameMode = enum {
	title_screen,
	gameplay
};

const State = struct {
	gamemode: GameMode = .title_screen,
	grid: level.Grid,
	camera: rl.Camera2D,

	pub fn init(world_config: level.WorldConfig, allocator: std.mem.Allocator)  !State {
		return .{
			.grid = try level.getRandomLevel(world_config, allocator),
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

fn updateGameplay(state: *State, delta_time: f32) !void {
	try handleTilePlacing(state);
	handleCameraMovement(&state.camera, delta_time);
}

fn drawGameplay(state: *State, spritesheet: rl.Texture2D) !void {
	// Drawing
	rl.beginDrawing();
	defer rl.endDrawing();

	rl.clearBackground(.sky_blue);
	rl.beginMode2D(state.camera);

	try level.drawGrid(&state.grid, spritesheet);
	rl.endMode2D();

	// Fixed Drawing
	try printInfo(state);
}

pub fn runGameLoop(allocator: std.mem.Allocator) !void {
	const world_config: level.WorldConfig = .{
		.width = 300,
		.height = 64,
	};
	var state = try State.init(world_config, allocator);
	const spritesheet = try rl.loadTexture("assets/dirt.png");

	while (!rl.windowShouldClose()) {
		const delta_time = rl.getFrameTime();
		switch (state.gamemode) {
			.gameplay => {
				try updateGameplay(&state, delta_time);
				try drawGameplay(&state, spritesheet);
			},
			.title_screen => {
				try updateGameplay(&state, delta_time);
				if (title_screen.draw()) { //TODO: FIgure out how to somehow separate the logic from drawing
					state.gamemode = .gameplay;
				}
			}
		}

	}
}

pub fn run(config: ?Config) !void { // TODO: Maybe clean this up
	const c = config orelse Config{
		.window_width = 1400,
		.window_height = 800
	};
	WINDOW_WIDTH = c.window_width;
	WINDOW_HEIGHT= c.window_height;
	rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hello, world!");
	defer rl.closeWindow();
	if (!rl.isWindowReady()) return error.InitWindow;

	var debug_allocator = std.heap.DebugAllocator(.{}).init;
	const allocator = debug_allocator.allocator();

	try runGameLoop(allocator);
}
