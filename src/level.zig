const std = @import("std");
const rl = @import("raylib");
const znoise = @import("znoise");

const helper = @import("helper.zig");
const tgen = @import("terrain_generation.zig");
pub const Grid = @import("Grid.zig");

const TILE_SIZE = 8;
const TILE_TEXTURE_SIZE = 9*2;

pub const WorldConfig = struct {
	seed: ?u64 = null,
	width: u64,
	height: u64
};

const Face = enum (u8) {
	r = 1,
	t = 2,
	l = 4,
	b = 8,
};

const Facing = packed struct {
	r: bool,
	t: bool,
	l: bool,
	b: bool,

	pub fn toInt(self: Facing) u4 {
		return
			@as(u4, @intFromBool(self.r)) +
			@as(u4, @intFromBool(self.t))*2 +
			@as(u4, @intFromBool(self.l))*4 +
			@as(u4, @intFromBool(self.b))*8;

	}
};

fn checkNeighborsAt(grid: *const Grid, x: u64, y: u64) !Facing {
	if (x == 0 or x == grid.width-1 or y == 0 or y == grid.height-1) return .{
		.r = false,
		.b = false,
		.l = false,
		.t = false
	};
	return .{
		.r = try grid.tileAt(x + 1, y) == .dirt,
		.l = try grid.tileAt(x - 1, y) == .dirt,
		.t = try grid.tileAt(x, y + 1) == .dirt,
		.b = try grid.tileAt(x, y - 1) == .dirt,
	};
}

fn getTextureRect(grid: *const Grid, x: u64, y: u64) !rl.Rectangle {
	var source_rect: rl.Rectangle = .{
		.width = TILE_SIZE,
		.height = TILE_SIZE,
		.x = 0,
		.y = 0,
	};

	const tile = try grid.tileAt(x, y);
	const yf: f32 = @floatFromInt(y);
	const xf: f32 = @floatFromInt(x);
	_ = xf; _ = yf;

	switch (tile) {
		.none => {
			source_rect.y = 0;
		},
		else => {
			source_rect.y = TILE_SIZE;
		}
	}

	const coords = (try checkNeighborsAt(grid, x, y)).toInt();
	source_rect.x = @floatFromInt(@as(u64, @intCast(coords))*TILE_SIZE);
	return source_rect;
}

pub fn getMouseGridPosition(grid: *const Grid, camera: rl.Camera2D) rl.Vector2 {
	const mouse_world_position = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
	return getGridPosition(
		grid,
		mouse_world_position,
	).clamp(.init(0, 0), .init(@floatFromInt(grid.width-1), @floatFromInt(grid.height-1)));
}


fn getCameraGridBounds(camera: rl.Camera2D, grid: *const Grid) struct{rl.Vector2, rl.Vector2} {
	const bounds = helper.getCameraBounds(camera);
	const top_left = getGridPosition(grid, bounds[0]);
	const bottom_right = getGridPosition(grid, bounds[1]); //TODO: handle inverted coordinates

	return .{top_left, bottom_right};
}

pub fn drawGrid(grid: *const Grid, camera: rl.Camera2D, spritesheet: rl.Texture2D) !void {
	const clamp = std.math.clamp;
	const bounds = getCameraGridBounds(camera, grid);

	const x0: u64 = @intFromFloat(clamp(bounds[0].x, 0, @as(f32, @floatFromInt(grid.width-1))));
	const y0: u64 = @intFromFloat(clamp(bounds[0].y, 0, @as(f32, @floatFromInt(grid.height-1))));
	const xe: u64 = @intFromFloat(clamp(bounds[1].x, 0, @as(f32, @floatFromInt(grid.width-1))));
	const ye: u64 = @intFromFloat(clamp(bounds[1].y, 0, @as(f32, @floatFromInt(grid.height-1))));
	// std.debug.print("grid: {} {} ||| {}, {}\n", .{x0, y0, xe, ye});

	var dest_rect: rl.Rectangle = .{
		.width = 8,
		.height = 8,
		.x = undefined,
		.y = undefined
	};

	for (ye..y0) |y| { // IMPORANT: Goes from bottom to top
		for (x0..xe+1) |x| { // Left to right
			const yf: f32 = @floatFromInt(y);
			const xf: f32 = @floatFromInt(x);
			dest_rect.x = xf*TILE_SIZE;
			dest_rect.y = (@as(f32, @floatFromInt(grid.height)) - yf)*TILE_SIZE;
			const source_rect = try getTextureRect(grid, x, y);
			rl.drawTexturePro(spritesheet, source_rect, dest_rect, .init(0, 0), 0, .white);
		}
	}
}

pub fn getRandomLevel(config: WorldConfig, allocator: std.mem.Allocator) !Grid {
	var seed: u64 = undefined;
	if (config.seed) |s| {
		seed = s;
	} else {
		try std.posix.getrandom(std.mem.asBytes(&seed));
	}

	return try tgen.newTerrain(config.width, config.height, seed, allocator);
}

pub fn getGridPosition(grid: *const Grid, pos: rl.Vector2) rl.Vector2 {
	return .init(
		@divFloor(pos.x, TILE_SIZE),
		@as(f32, @floatFromInt(grid.height)) - @divFloor(pos.y, TILE_SIZE),
	);
}
