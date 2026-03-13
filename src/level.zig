const std = @import("std");
const rl = @import("raylib");
const znoise = @import("znoise");

const TILE_SIZE = 8;
const TILE_TEXTURE_SIZE = 9*2;

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

pub const Grid = struct {
	const Tile = enum {
		none,
		dirt,
		stone,
	};

	const GridError = error{
		OutOfBounds
	};

	tiles: []Tile,
	width: u64,
	height: u64,

	pub fn init(width: u64, height: u64, allocator: std.mem.Allocator) !Grid {
		const tiles = try allocator.alloc(Tile, width*height);
		for (0..width*height) |i| {
			tiles[i] = .none;
		}
		return .{
			.tiles = tiles,
			.width = width,
			.height = height
		};
	}

	pub fn tileRefAt(self: *Grid, x: u64, y: u64) GridError!*Tile {
		return &self.tiles[y * self.width + x];
	}

	pub fn tileAt(self: Grid, x: u64, y: u64) GridError!Tile {
		return self.tiles[y * self.width + x];
	}

	pub fn placeTile(self: *Grid, x: u64, y: u64, tile: Tile) GridError!void{
		const tile_to_change= try self.tileRefAt(x, y);
		tile_to_change.* = tile;
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

pub fn drawGrid(grid: *const Grid, spritesheet: rl.Texture2D) !void {
	var dest_rect: rl.Rectangle = .{
		.width = 8,
		.height = 8,
		.x = undefined,
		.y = undefined
	};
	for (0..grid.height-1) |y| {
		for (0..grid.width-1) |x| {
			const yf: f32 = @floatFromInt(y);
			const xf: f32 = @floatFromInt(x);
			dest_rect.x = xf*TILE_SIZE;
			dest_rect.y = (@as(f32, @floatFromInt(grid.height)) - yf)*TILE_SIZE;
			const source_rect = try getTextureRect(grid, x, y);
			rl.drawTexturePro(spritesheet, source_rect, dest_rect, .init(0, 0), 0, .white);
		}
	}
}

pub fn getGridPosition(grid: Grid, pos: rl.Vector2, camera: rl.Camera2D) rl.Vector2 {
	const pos2 = rl.getScreenToWorld2D(pos, camera);
	return .init(
		@divFloor(pos2.x, TILE_SIZE),
		@as(f32, @floatFromInt(grid.height)) - @divFloor(pos2.y, TILE_SIZE),
	);
}

fn terrainHeight(x: u64, seed: u64) u64 {
	const frequency: f32 = 0.65;
	const amplitude: f32 = 20;
	const base_height: f32 = 45;

	const gen: znoise.FnlGenerator = .{
		.noise_type = .perlin,
		.seed = @bitCast(@as(u32, @truncate(seed))) //TODO: use XOR folding for better randomness
	};
	const n = gen.noise2(
		@as(f32, @floatFromInt(x))*frequency,
		0
	);
	return @intFromFloat(base_height + amplitude * n);
}

pub fn newTerrain(width: u64, height: u64, seed: u64, allocator: std.mem.Allocator) !Grid {
	var grid: Grid = try .init(width, height, allocator);
	for (0..grid.width-1) |x| {
		const h = terrainHeight(x, seed);
		for (0..grid.height-1) |y| {
			if (y < h) {
				const tile = try grid.tileRefAt(x, y);
				tile.* = .dirt;
			}
		}
	}
	return grid;

}
