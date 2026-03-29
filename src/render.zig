const std = @import("std");
const rl = @import("raylib");
const rgui = @import("raygui");
const level = @import("level.zig");
const State = @import("State.zig");

const Bitmap = []u4;

fn setShaderUniform(shader: rl.Shader, value: *const anyopaque, name: []const u8, value_type: rl.ShaderUniformDataType) !void {
	var buffer: [128]u8 = undefined;
	const string = try std.fmt.bufPrintZ(&buffer, "{s}", .{name});
	const loc = rl.getShaderLocation(shader, string);
	rl.setShaderValue(shader, loc, value, value_type);
}

pub const RenderState = struct {
	target: rl.RenderTexture2D,
	bitmap: Bitmap,
	modified_world: bool = true,
	shader: rl.Shader,
	spritesheet: rl.Texture2D,
	vignette: struct {
		radius1: f32,
		radius2: f32
	}
,

	pub fn init(allocator: std.mem.Allocator) !RenderState {
		const spritesheet = try rl.loadTexture("assets/tiles.png");
		const bitmap = try allocator.alloc(u4, 1000*1000);
		const target = try rl.loadRenderTexture(rl.getScreenWidth(), rl.getScreenHeight());

		const path: [:0]const u8 = "assets/scary_vignette.frag\x00";
		const shader = try rl.loadShader(null, path);

		const state: RenderState = .{
			.spritesheet = spritesheet,
			.shader = shader,
			.bitmap = bitmap,
			.vignette = .{
				.radius1 = 0.1,
				.radius2 = 0.8
			},
			.target = target
		};

		const color: [3]f32 = .{0.8, 0.2, 0.2};
		try setShaderUniform(shader, &color, "coolColor", .vec3);
		try setShaderUniform(shader, &state.vignette.radius1, "radius1", .float);
		try setShaderUniform(shader, &state.vignette.radius2, "radius2", .float);

		const res: [2]f32 = .{@floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight())};
		try setShaderUniform(shader, &res, "resolution", .vec2);

		return state;
	}
};

fn getOpenGLPosition(vector: rl.Vector2) rl.Vector2 {
	const width: f32 = @floatFromInt(rl.getScreenWidth());
	const height: f32 = @floatFromInt(rl.getScreenHeight());

	const uv: rl.Vector2 = rl.Vector2.divide(vector, .init(width, height))
		.scale(2).subtract(.init(1,1))
		.multiply(.init(width/height, -1));
	return uv;
}

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

pub fn render(state: *const State, render_state: *RenderState) !void {
	// Update shader
	const center = getOpenGLPosition(rl.getMousePosition());
	const vals: [2]f32 = .{center.x, center.y};
	try setShaderUniform(render_state.shader, &vals, "center", .vec2);

	// World
	rl.beginTextureMode(render_state.target);
		rl.clearBackground(.sky_blue);

		rl.beginMode2D(state.camera);

		try level.drawGrid(&state.grid, render_state.bitmap, render_state.modified_world, state.camera, render_state.spritesheet);
		rl.endMode2D();
	rl.endTextureMode();

	// Drawing
	rl.beginDrawing();
		rl.clearBackground(.black);
		if (state.shader_index == 1) rl.beginShaderMode(render_state.shader);

		rl.drawTextureRec(
			render_state.target.texture,
			.init(0, 0, @floatFromInt(rl.getScreenWidth()), @floatFromInt(-1 * rl.getScreenHeight())),
			.init(0, 0),
			.white
		);
		rl.endShaderMode();

		// Fixed Drawing
		try printInfo(state);
		rl.drawFPS(10, 100);
	rl.endDrawing();
}
