/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- SYSTEM ---
import 'dart:async';
import 'dart:io';

// ---- EXTERNAL ---
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// ---- LOCAL ---
import '../services/error_reporting_service.dart';

// ---- MAJOR ---
// Global Application Logger
// Manages filesystem persistence, stream broadcasting, and console output.
class AppLogger {
  // --- Sub
  // Singleton Pattern
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  // --- Sub
  // State Containers
  File? _logFile;
  IOSink? _sink;
  bool _initialized = false;
  bool isDebugEnabled = false;
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  // --- Sub
  // Lifecycle Management
  Future<void> init({bool debug = false}) async {
    if (_initialized) return;
    isDebugEnabled = debug;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rootify_app.log');

      // Comment: Perform rotation if log exceeds 5MB threshold
      if (file.existsSync() && file.lengthSync() > 5 * 1024 * 1024) {
        final backup = File('${dir.path}/rootify_app.log.old');
        if (backup.existsSync()) await backup.delete();
        await file.rename(backup.path);
      }

      _logFile = file;
      _sink = _logFile!.openWrite(mode: FileMode.append);
      _initialized = true;

      _write("=== SESSION STARTED: ${DateTime.now()} ===");
    } catch (e) {
      debugPrint("AppLogger: Initialization failed -> $e");
    }
  }

  // --- Sub
  // Public Diagnostic Rails
  void d(String m) {
    if (isDebugEnabled) _log("DEBUG", m, "34"); // Comment: Neon Blue
  }

  void i(String m) => _log("INFO", m, "32"); // Comment: Success Green
  void w(String m) => _log("WARN", m, "33"); // Comment: Amber Warning

  void e(String m, [Object? err, StackTrace? st, bool report = false]) {
    _log("ERROR", "$m ${err ?? ''} ${st ?? ''}", "31"); // Comment: Critical Red

    // Auto-Report Logic
    if (report) {
      ErrorReportingService.handleStatic(err ?? m, st);
    }
  }

  // --- Sub
  // Core Dispatcher
  void _log(String level, String message, String ansiCode) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final formatted = "[$timestamp] [$level] $message";

    if (kDebugMode) {
      // Comment: Platform-specific terminal escape sequences
      print('\x1B[${ansiCode}m$formatted\x1B[0m');
    }

    _write(formatted);
    if (!_logController.isClosed) {
      _logController.add(formatted);
    }
  }

  void _write(String line) {
    if (!_initialized || _sink == null) return;
    _sink!.writeln(line);
  }

  // --- Sub
  // Maintenance Utilities
  Future<void> clearLogs() async {
    if (!_initialized) return;

    await _sink?.flush();
    await _sink?.close();

    if (_logFile?.existsSync() ?? false) {
      _logFile!.writeAsStringSync("");
    }

    _sink = _logFile?.openWrite(mode: FileMode.append);
    _write("=== LOGS CLEARED ===");
  }

  Future<String> getLogs() async {
    if (_logFile == null || !_logFile!.existsSync()) return "Log file empty.";
    return _logFile!.readAsString();
  }

  String? get logPath => _logFile?.path;
}

// ---- MAJOR ---
// Global Reference
final logger = AppLogger();
