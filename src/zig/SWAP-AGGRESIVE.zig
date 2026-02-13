// Copyright (C) 2026 Rootify - Aby - FoxLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ---- SYSTEM ---
const std = @import("std");
const fs = std.fs;
const process = std.process;

// ---- MAIN ----
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try process.argsAlloc(allocator);
    if (args.len < 2) {
        std.debug.print("Usage: SWAP-AGGRESIVE <val>\n", .{});
        std.process.exit(1);
    }

    try apply(args[1]);
}

// ---- FUNCTIONS ----
pub fn apply(val: []const u8) !void {
    const path = "/proc/sys/vm/swappiness";
    const file = try fs.openFileAbsolute(path, .{ .mode = .write_only });
    defer file.close();
    try file.writeAll(val);
    try file.writeAll("\n");
}
