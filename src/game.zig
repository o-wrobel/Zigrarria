const std = @import("std");

const rl = @import("raylib");
const rgui = @import("raygui");
const znoise = @import("znoise");

const helper = @import("helper.zig");
const title_screen = @import("title_screen.zig");
const level = @import("level.zig");
const Grid = level.Grid;
const Bitmap = []u4;

const camera_move_speed = 660;

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
	modified_world: bool = true,
	make_scary: bool = false,

	pub fn init(world_config: level.WorldConfig, allocator: std.mem.Allocator)  !State {
		return .{
			.grid = try level.getRandomLevel(world_config, allocator),
			.camera = .{
				.offset = .init(
					@divFloor(@as(f32, @floatFromInt(rl.getScreenWidth())),2),
					@divFloor(@as(f32, @floatFromInt(rl.getScreenHeight())),2),
				),
				.rotation = 0,
				.target = .init(0, 0),
				.zoom = 1
			},
		};
	}
};

fn printInfo(state: *const State) !void {
	const mouse_grid_position = level.getMouseGridPosition(&state.grid, state.camera);
	var buffer: [128]u8 = undefined;
	const string = try std.fmt.bufPrintZ(
		&buffer,
		"{s}, {}, {}",
		.{
			@tagName(
				state.grid.tileAt(
					@intFromFloat(mouse_grid_position.x),
					@intFromFloat(mouse_grid_position.y)
				) catch .none
			),
			mouse_grid_position.x,
			mouse_grid_position.y,
		}
	);
	const rect: rl.Rectangle = .init(10, 10, 100, 20);
	_=rgui.statusBar(rect, string);
}

fn updateCamera(camera: *rl.Camera2D, delta_time: f32) void {
	if (rl.isKeyDown(.a)) camera.target.x -= camera_move_speed*delta_time;
	if (rl.isKeyDown(.w)) camera.target.y -= camera_move_speed*delta_time;
	if (rl.isKeyDown(.d)) camera.target.x += camera_move_speed*delta_time;
	if (rl.isKeyDown(.s)) camera.target.y += camera_move_speed*delta_time;

	const delta = rl.getMouseWheelMove();
	camera.zoom += delta * 0.4 * camera.zoom;
}

fn handleTilePlacing(state: *State) !bool {
	if (rl.isMouseButtonDown(.left)) {
		const mouse_grid_position = level.getMouseGridPosition(&state.grid, state.camera);
		const x: u64 = @intFromFloat(mouse_grid_position.x);
		const y: u64 = @intFromFloat(mouse_grid_position.y);
		try state.grid.setTile(x, y, .stone);
		return true;
	}
	return false;
}

fn updateGameplay(state: *State, delta_time: f32) !void {
	state.modified_world = try handleTilePlacing(state);
	if (rl.isKeyPressed(.x)) state.make_scary = true;

	updateCamera(&state.camera, delta_time);
}

fn drawGameplay(state: *State, bitmap: Bitmap, spritesheet: rl.Texture2D, shader: rl.Shader) !void {
	// Drawing
	rl.beginDrawing();
	defer rl.endDrawing();

	rl.clearBackground(.sky_blue);
	if (state.make_scary) {
		rl.beginShaderMode(shader);
		rl.clearBackground(.black);
	}

	rl.beginMode2D(state.camera);

	try level.drawGrid(&state.grid, bitmap, state.modified_world, state.camera, spritesheet);
	rl.endMode2D();
	rl.endShaderMode();

	// Fixed Drawing
	try printInfo(state);
	rl.drawFPS(10, 100);
}

pub fn runGameLoop(allocator: std.mem.Allocator) !void {
	const world_config: level.WorldConfig = .{
		.width = 300,
		.height = 64,
	};
	var state = try State.init(world_config, allocator);
	const spritesheet = try rl.loadTexture("assets/tiles.png");

	const path: [:0]const u8 = "assets/my_shader.frag\x00";
	const shader = try rl.loadShader(null, path);
	const loc = rl.getShaderLocation(shader, "coolColor\x00");
	const color: [3]f32 = .{0.8, 0.2, 0.2};
	rl.setShaderValue(shader, loc, &color, .vec3);

	const bitmap = try allocator.alloc(u4, state.grid.width*state.grid.height);
	defer allocator.free(bitmap);

	while (!rl.windowShouldClose()) {
		const delta_time = rl.getFrameTime();
		switch (state.gamemode) {
			.gameplay => {
				try updateGameplay(&state, delta_time);
				try drawGameplay(&state, bitmap, spritesheet, shader);
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
		.window_width = 1480,
		.window_height = 720
	}; //Must be multiple of 8 (TILE_SIZE)
	rl.initWindow(c.window_width, c.window_height, "Hello, world!");
	defer rl.closeWindow();
	if (!rl.isWindowReady()) return error.InitWindow;

	var debug_allocator = std.heap.DebugAllocator(.{}).init;
	const allocator = debug_allocator.allocator();

	try runGameLoop(allocator);
}
