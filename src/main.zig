const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
    try game.run(400, 300);
}
