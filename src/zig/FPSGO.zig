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
    if (args.len < 4) {
        printUsage();
        std.process.exit(1);
    }

    const command = args[1];
    const path_or_node = args[2];
    const value = args[3];

    if (std.mem.eql(u8, command, "enable")) {
        try applyEnable(path_or_node, value);
    } else if (std.mem.eql(u8, command, "mode")) {
        try applyMode(path_or_node, value);
    } else if (std.mem.eql(u8, command, "set")) {
        try applySet(path_or_node, value);
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        printUsage();
        std.process.exit(1);
    }
}

// ---- MODULAR ----

pub fn applyEnable(basePath: []const u8, value: []const u8) !void {
    const target_nodes = [_][]const u8{ "fpsgo_enable", "fbt_enable", "enabled" };
    for (target_nodes) |node| {
        var path_buf: [512]u8 = undefined;
        const full_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ basePath, node }) catch continue;
        writeValue(full_path, value) catch continue;
    }
}

pub fn applyMode(basePath: []const u8, value: []const u8) !void {
    var path_buf: [512]u8 = undefined;
    const mode_path = std.fmt.bufPrint(&path_buf, "{s}/mode", .{basePath}) catch return error.FormatFailed;
    writeValue(mode_path, value) catch {
        const profile_path = std.fmt.bufPrint(&path_buf, "{s}/profile", .{basePath}) catch return error.FormatFailed;
        try writeValue(profile_path, value);
    };
}

pub fn applySet(fullPath: []const u8, value: []const u8) !void {
    try writeValue(fullPath, value);
}

// ---- HELPERS ----

fn writeValue(path: []const u8, value: []const u8) !void {
    const file = fs.openFileAbsolute(path, .{ .mode = .write_only }) catch return error.OpenFailed;
    defer file.close();
    try file.writeAll(value);
    if (!std.mem.endsWith(u8, value, "\n")) {
        try file.writeAll("\n");
    }
}

fn printUsage() void {
    std.debug.print(
        \\MediaTek FPSGO Tuning Binary
        \\Usage: FPSGO <command> <path/param> <value>
        \\
        \\Commands:
        \\  enable <base_path> <1|0>      Enable/Disable FPSGo (tries multiple nodes)
        \\  mode   <base_path> <mode>     Set mode/profile
        \\  set    <full_path> <value>    Set granular parameter
        \\
    , .{});
}
