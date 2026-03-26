const std = @import("std");
pub const Grid = @This();

pub const Tile = enum {
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

pub fn getIndex(self: *const Grid, x: u64, y: u64) u64 {
	return y*self.width + x;
}

pub fn tileAt(self: *const Grid, x: u64, y: u64) !Tile {
	if ((0 <= x and x < self.width) and (0 <= x and x < self.width)) {
		return self.tiles[getIndex(self, x, y)];
	} else {
		return GridError.OutOfBounds;
	}
}

pub fn setTile(self: *Grid, x: u64, y: u64, tile_type: Tile) GridError!void {
	if ((0 <= x and x < self.width) and (0 <= x and x < self.width)) {
		self.tiles[getIndex(self, x, y)] = tile_type;
	} else {
		return GridError.OutOfBounds;
	}
}
