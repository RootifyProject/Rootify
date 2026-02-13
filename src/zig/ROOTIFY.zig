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

// ---- CONSTANTS ---
const MODULE_BASE = "/data/adb/modules/rootify";
const BIN_DIR = MODULE_BASE ++ "/bin";
const SHELL_DIR = MODULE_BASE ++ "/shell";
const CONFIGS_DIR = MODULE_BASE ++ "/configs";

// ---- MAJOR ---
// Rootify Master Core - "Pusat" Monolithic Edition
// This file is self-contained and handles all systemless orchestration.
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try process.argsAlloc(allocator);
    if (args.len < 2) {
        printUsage();
        return;
    }

    const command = std.mem.trim(u8, args[1], " \n\r\t");

    if (std.mem.eql(u8, command, "init")) {
        try handleInit();
    } else if (std.mem.eql(u8, command, "boot")) {
        try handleBoot(allocator);
    } else if (std.mem.eql(u8, command, "governor")) {
        if (args.len < 4) return error.MissingArgs;
        try applyGovernor(std.mem.trim(u8, args[2], " \n\r\t"), std.mem.trim(u8, args[3], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "minfreq")) {
        if (args.len < 4) return error.MissingArgs;
        try applyMinFreq(std.mem.trim(u8, args[2], " \n\r\t"), std.mem.trim(u8, args[3], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "maxfreq")) {
        if (args.len < 4) return error.MissingArgs;
        try applyMaxFreq(std.mem.trim(u8, args[2], " \n\r\t"), std.mem.trim(u8, args[3], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "zram-size")) {
        if (args.len < 3) return error.MissingArgs;
        try applyZramSize(std.mem.trim(u8, args[2], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "zram-algo")) {
        if (args.len < 3) return error.MissingArgs;
        try applyZramAlgo(std.mem.trim(u8, args[2], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "swap-aggresive")) {
        if (args.len < 3) return error.MissingArgs;
        try applySwappiness(std.mem.trim(u8, args[2], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "vfs-cache")) {
        if (args.len < 3) return error.MissingArgs;
        try applyVfsCache(std.mem.trim(u8, args[2], " \n\r\t"));
    } else if (std.mem.eql(u8, command, "fpsgo")) {
        if (args.len < 3) return error.MissingArgs;
        const sub_cmd = std.mem.trim(u8, args[2], " \n\r\t");
        if (std.mem.eql(u8, sub_cmd, "enable")) {
            if (args.len < 5) return error.MissingArgs;
            try applyFpsGoEnable(std.mem.trim(u8, args[3], " \n\r\t"), std.mem.trim(u8, args[4], " \n\r\t"));
        } else if (std.mem.eql(u8, sub_cmd, "mode")) {
            if (args.len < 5) return error.MissingArgs;
            try applyFpsGoMode(std.mem.trim(u8, args[3], " \n\r\t"), std.mem.trim(u8, args[4], " \n\r\t"));
        } else if (std.mem.eql(u8, sub_cmd, "set")) {
            if (args.len < 5) return error.MissingArgs;
            try applyFpsGoSet(std.mem.trim(u8, args[3], " \n\r\t"), std.mem.trim(u8, args[4], " \n\r\t"));
        }
    } else if (std.mem.eql(u8, command, "reset")) {
        try handleReset(allocator);
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        printUsage();
        std.process.exit(1);
    }
}

fn printUsage() void {
    std.debug.print(
        \\Rootify Master Core (Monolithic)
        \\Usage: ROOTIFY <command> [args...]
        \\
        \\System Commands:
        \\  init                          Initialize module environment
        \\  boot                          Apply all persistent settings
        \\  reset                         Stop all services and reset defaults
        \\
        \\CPU Commands:
        \\  governor <cluster> <val>      Set scaling governor
        \\  minfreq  <cluster> <val>      Set scaling min frequency
        \\  maxfreq  <cluster> <val>      Set scaling max frequency
        \\
        \\ZRAM Commands:
        \\  zram-size <mb>                Set ZRAM size in MB
        \\  zram-algo <algo>              Set ZRAM compression algorithm
        \\  swap-aggresive <val>          Set VM swappiness
        \\  vfs-cache <val>               Set VM VFS cache pressure
        \\
        \\FPSGo Commands:
        \\  fpsgo enable <path> <1|0>     Enable/Disable FPSGo
        \\  fpsgo mode   <path> <mode>    Set FPSGo mode/profile
        \\  fpsgo set    <path> <val>     Set granular FPSGo parameter
        \\
    , .{});
}

// ---- LOGIC: System ---

fn handleInit() !void {
    const dirs = [_][]const u8{ "shell", "config", "logs", "configs", "bin" };
    for (dirs) |dir| {
        fs.cwd().makePath(dir) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };
    }
    std.debug.print("ROOTIFY: Environment Initialized.\n", .{});
}

fn handleBoot(allocator: std.mem.Allocator) !void {
    std.debug.print("ROOTIFY: Starting Boot Sequence...\n", .{});
    // CPU
    try applyPersistentCpu(allocator, "GOVERNOR", "governor");
    try applyPersistentCpu(allocator, "MINFREQ", "minfreq");
    try applyPersistentCpu(allocator, "MAXFREQ", "maxfreq");
    // ZRAM
    try applyPersistentZram(allocator);
    // FPSGo
    try applyPersistentFpsGo(allocator);
    // Laya
    try applyLayaServices(allocator);
    std.debug.print("ROOTIFY: Boot Sequence Complete.\n", .{});
}

// ---- LOGIC: CPU ---

fn applyGovernor(cluster: []const u8, value: []const u8) !void {
    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/sys/devices/system/cpu/cpufreq/policy{s}/scaling_governor", .{cluster});
    try writeNode(path, value);
}

fn applyMinFreq(cluster: []const u8, value: []const u8) !void {
    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/sys/devices/system/cpu/cpufreq/policy{s}/scaling_min_freq", .{cluster});
    try writeNode(path, value);
}

fn applyMaxFreq(cluster: []const u8, value: []const u8) !void {
    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/sys/devices/system/cpu/cpufreq/policy{s}/scaling_max_freq", .{cluster});
    try writeNode(path, value);
}

// ---- LOGIC: ZRAM ---

fn applyZramSize(mb_str: []const u8) !void {
    const mb = std.fmt.parseInt(u64, mb_str, 10) catch return error.InvalidValue;
    const bytes = mb * 1024 * 1024;
    var buf: [64]u8 = undefined;
    const val = try std.fmt.bufPrint(&buf, "{}", .{bytes});
    try writeNode("/sys/block/zram0/disksize", val);
}

fn applyZramAlgo(algo: []const u8) !void {
    try writeNode("/sys/block/zram0/comp_algorithm", algo);
}

fn applySwappiness(val: []const u8) !void {
    try writeNode("/proc/sys/vm/swappiness", val);
}

fn applyVfsCache(val: []const u8) !void {
    try writeNode("/proc/sys/vm/vfs_cache_pressure", val);
}

// ---- LOGIC: FPSGO ---

fn applyFpsGoEnable(basePath: []const u8, value: []const u8) !void {
    const target_nodes = [_][]const u8{ "fpsgo_enable", "fbt_enable", "enabled" };
    for (target_nodes) |node| {
        var path_buf: [512]u8 = undefined;
        const full_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ basePath, node }) catch continue;
        writeNode(full_path, value) catch continue;
    }
}

fn applyFpsGoMode(basePath: []const u8, value: []const u8) !void {
    var path_buf: [512]u8 = undefined;
    const mode_path = try std.fmt.bufPrint(&path_buf, "{s}/mode", .{basePath});
    writeNode(mode_path, value) catch {
        const profile_path = try std.fmt.bufPrint(&path_buf, "{s}/profile", .{basePath});
        try writeNode(profile_path, value);
    };
}

fn applyFpsGoSet(fullPath: []const u8, value: []const u8) !void {
    try writeNode(fullPath, value);
}

// ---- HELPERS: System ---

fn applyPersistentCpu(allocator: std.mem.Allocator, data_file: []const u8, cmd: []const u8) !void {
    const dataPath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ CONFIGS_DIR, data_file });
    const file = fs.openFileAbsolute(dataPath, .{}) catch return;
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 1024 * 64);
    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        if (std.mem.indexOf(u8, line, ":")) |sep_idx| {
            const idx_str = std.mem.trim(u8, line[0..sep_idx], " \r\t");
            const value = std.mem.trim(u8, line[sep_idx + 1 ..], " \r\t");
            if (value.len > 0) {
                if (std.mem.eql(u8, cmd, "governor")) {
                    applyGovernor(idx_str, value) catch {};
                } else if (std.mem.eql(u8, cmd, "minfreq")) {
                    applyMinFreq(idx_str, value) catch {};
                } else {
                    applyMaxFreq(idx_str, value) catch {};
                }
            }
        }
    }
}

fn applyPersistentZram(allocator: std.mem.Allocator) !void {
    if (readSingleValue(allocator, "ZRAM-ALGHORITM")) |val| {
        applyZramAlgo(val) catch {};
    }
    if (readSingleValue(allocator, "ZRAM-SIZE")) |val| {
        applyZramSize(val) catch {};
    }
    if (readSingleValue(allocator, "SWAP-AGGRESIVE")) |val| {
        applySwappiness(val) catch {};
    }
    if (readSingleValue(allocator, "VFS-CACHE")) |val| {
        applyVfsCache(val) catch {};
    }
}

fn applyPersistentFpsGo(allocator: std.mem.Allocator) !void {
    const dataPath = CONFIGS_DIR ++ "/FPSGO";
    const file = fs.openFileAbsolute(dataPath, .{}) catch return;
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 1024 * 64);
    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;
        var part_it = std.mem.splitScalar(u8, trimmed, ':');
        const cmd = part_it.next() orelse continue;
        const path = part_it.next() orelse continue;
        const val = part_it.next() orelse continue;
        
        if (std.mem.eql(u8, cmd, "enable")) {
            applyFpsGoEnable(path, val) catch {};
        } else if (std.mem.eql(u8, cmd, "mode")) {
            applyFpsGoMode(path, val) catch {};
        } else {
            applyFpsGoSet(path, val) catch {};
        }
    }
}

fn applyLayaServices(allocator: std.mem.Allocator) !void {
    const services = [_][]const u8{ "BATTMON", "KERTUN", "THERMAL" };
    for (services) |service| {
        const dataPath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ CONFIGS_DIR, service });
        const file = fs.openFileAbsolute(dataPath, .{}) catch continue;
        const content = file.readToEndAlloc(allocator, 1024) catch continue;
        file.close();
        if (std.mem.indexOf(u8, content, "applyonBoot?: true") != null) {
            const scriptName = try std.fmt.allocPrint(allocator, "{s}.sh", .{service});
            const scriptPath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ SHELL_DIR, scriptName });
            _ = runCmd(allocator, &[_][]const u8{ "/system/bin/sh", scriptPath }) catch {};
        }
    }
}

// ---- HELPERS ---

fn writeNode(path: []const u8, value: []const u8) !void {
    const file = fs.openFileAbsolute(path, .{ .mode = .write_only }) catch |err| {
        std.debug.print("Failed to open {s}: {}\n", .{path, err});
        return error.OpenFailed;
    };
    defer file.close();
    
    // ATOMIC WRITE: Combine value + newline into a single write call
    var write_buf: [1024]u8 = undefined;
    const final_val = if (!std.mem.endsWith(u8, value, "\n")) 
                        std.fmt.bufPrint(&write_buf, "{s}\n", .{value}) catch value
                      else value;
                      
    file.writeAll(final_val) catch |err| {
        std.debug.print("Failed to write '{s}' to {s}: {}\n", .{value, path, err});
        return err;
    };
}

fn readSingleValue(allocator: std.mem.Allocator, filename: []const u8) ?[]const u8 {
    const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ CONFIGS_DIR, filename }) catch return null;
    const file = fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const content = file.readToEndAlloc(allocator, 1024) catch return null;
    return std.mem.trim(u8, content, " \n\r\t");
}

fn handleReset(allocator: std.mem.Allocator) !void {
    std.debug.print("ROOTIFY: Resetting System to Defaults...\n", .{});
    
    // 1. Kill Laya Services & Logcat
    _ = runCmd(allocator, &[_][]const u8{ "pkill", "-f", "laya-kernel-tuner" }) catch {};
    _ = runCmd(allocator, &[_][]const u8{ "pkill", "-f", "laya-battery-monitor" }) catch {};
    _ = runCmd(allocator, &[_][]const u8{ "pkill", "-f", "logcat" }) catch {}; // Aggressive stop

    // 2. CPU Defaults (Schedutil is safest)
    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        var buf: [2]u8 = undefined;
        const cluster = std.fmt.bufPrint(&buf, "{}", .{i}) catch continue;
        applyGovernor(cluster, "schedutil") catch {};
    }

    // 3. ZRAM Cleanup
    _ = runCmd(allocator, &[_][]const u8{ "swapoff", "/dev/block/zram0" }) catch {};

    std.debug.print("ROOTIFY: Reset Complete.\n", .{});
}

fn runCmd(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, allocator);
    _ = try child.spawnAndWait();
}

// ---- END OF FILE ---
// Rootify App - Rootify Projects - Aby - 2026
