const std = @import("std");
pub const Grid = @This();

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
