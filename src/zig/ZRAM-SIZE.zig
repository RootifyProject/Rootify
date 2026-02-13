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
        std.debug.print("Usage: ZRAM-SIZE <value_in_MB>\n", .{});
        std.process.exit(1);
    }

    try apply(args[1]);
}

// ---- FUNCTIONS ----
pub fn apply(value_str: []const u8) !void {
    const value_mb = std.fmt.parseInt(u64, value_str, 10) catch {
        std.debug.print("Invalid MB value: {s}\n", .{value_str});
        std.process.exit(1);
    };
    const value_bytes = value_mb * 1024 * 1024;

    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/sys/block/zram0/disksize", .{});

    const file = try fs.openFileAbsolute(path, .{ .mode = .write_only });
    defer file.close();
    
    var size_buf: [64]u8 = undefined;
    const size_str = try std.fmt.bufPrint(&size_buf, "{}", .{value_bytes});
    try file.writeAll(size_str);
    try file.writeAll("\n");
}
