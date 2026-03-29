const std = @import("std");
const rl = @import("raylib");
const level = @import("level.zig");

const State = @This();

pub const GameMode = enum {
	title_screen,
	gameplay
};

gamemode: GameMode = .title_screen,
grid: level.Grid,
camera: rl.Camera2D,
shader_index: u8 = 0,

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
