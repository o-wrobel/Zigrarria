const std = @import("std");

const rl = @import("raylib");
const rgui = @import("raygui");
const znoise = @import("znoise");

const title_screen = @import("title_screen.zig");
const level = @import("level.zig");
const rdr = @import("render.zig");
const State = @import("State.zig");

const RenderState = rdr.RenderState;
const Grid = level.Grid;

const camera_move_speed = 660;

pub const Config = struct {
	window_width: i32,
	window_height: i32,
};

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

pub fn runGameLoop(allocator: std.mem.Allocator) !void {
	const world_config: level.WorldConfig = .{
		.width = 300,
		.height = 64,
	};
	var state = try State.init(world_config, allocator);

	var render_state: RenderState = try .init(allocator);

	while (!rl.windowShouldClose()) {
		const delta_time = rl.getFrameTime();
		switch (state.gamemode) {
			.gameplay => {
				try updateGameplay(&state, delta_time);
				try rdr.render(&state, &render_state);
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
