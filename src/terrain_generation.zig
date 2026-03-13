const std = @import("std");
const znoise = @import("znoise");

const Grid = @import("Grid.zig");

fn terrainHeight(x: u64, gen: znoise.FnlGenerator) u64 {
	const frequency: f32 = 0.65;
	const amplitude: f32 = 20;
	const base_height: f32 = 45;

	const n = gen.noise2(
		@as(f32, @floatFromInt(x))*frequency,
		0
	);
	return @intFromFloat(base_height + amplitude * n);
}

pub fn newTerrain(width: u64, height: u64, seed: u64, allocator: std.mem.Allocator) !Grid {
	var grid: Grid = try .init(width, height, allocator);

	const gen: znoise.FnlGenerator = .{
		.noise_type = .perlin,
		.seed = @bitCast(@as(u32, @truncate(seed))) //TODO: use XOR folding for better randomness
	};

	for (0..grid.width-1) |x| {
		const h = terrainHeight(x, gen);
		for (0..grid.height-1) |y| {
			if (y < h) {
				const tile = try grid.tileRefAt(x, y);
				tile.* = .dirt;
			}
		}
	}
	return grid;
}
