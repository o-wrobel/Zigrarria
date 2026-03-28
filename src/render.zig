const std = @import("std");
const rl = @import("raylib");
const level = @import("level.zig");

const Bitmap = []u4;

const Vignette = struct {
	radius1: f32,
	radius2: f32
};

pub const State = struct {
	target: rl.RenderTexture2D,
	bitmap: Bitmap,
	shader: rl.Shader,
	spritesheet: rl.Texture2D,
	vignette: Vignette,

	pub fn init(allocator: std.mem.Allocator) !State {
		const spritesheet = try rl.loadTexture("assets/tiles.png");
		const bitmap = try allocator.alloc(u4, 1000*1000);
		const target = try rl.loadRenderTexture(rl.getScreenWidth(), rl.getScreenHeight());

		const vignette: Vignette = .{
			.radius1 = 0,
			.radius2 = 1.5
		};

		const path: [:0]const u8 = "assets/my_shader.frag\x00";
		const shader = try rl.loadShader(null, path);
		{
			const loc = rl.getShaderLocation(shader, "radius1\x00");
			rl.setShaderValue(shader, loc, &vignette.radius1, .float);
		}
		{
			const loc = rl.getShaderLocation(shader, "radius2\x00");
			rl.setShaderValue(shader, loc, &vignette.radius2, .float);
		}
		{
			const loc = rl.getShaderLocation(shader, "coolColor\x00");
			const color: [3]f32 = .{0.8, 0.2, 0.2};
			rl.setShaderValue(shader, loc, &color, .vec3);
		}
		{
			const loc = rl.getShaderLocation(shader, "res\x00");
			const res: [2]f32 = .{@floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight())};
			rl.setShaderValue(shader, loc, &res, .vec2);
		}

		return .{
			.spritesheet = spritesheet,
			.shader = shader,
			.bitmap = bitmap,
			.vignette = vignette,
			.target = target
		};
	}
};
