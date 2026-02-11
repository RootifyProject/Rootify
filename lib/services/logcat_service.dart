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
import 'dart:convert';
import 'dart:io';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Logcat Runtime Configuration
class LogcatConfig {
  final String buffer; // e.g., "main", "system", "all"
  final String level; // e.g., "V", "D", "I", "W", "E"
  final String? filter; // custom tag filters
  final String? extraArgs; // custom additional args

  LogcatConfig({
    this.buffer = "all",
    this.level = "V",
    this.filter,
    this.extraArgs,
  });

  // --- Sub
  // Parameter Construction
  List<String> toArgs() {
    List<String> args = ["-v", "time"];
    args.addAll(["-b", buffer]);
    args.addAll(["*:$level"]);
    if (filter != null && filter!.isNotEmpty) {
      args.add(filter!);
    }
    if (extraArgs != null && extraArgs!.isNotEmpty) {
      args.addAll(extraArgs!.split(' '));
    }
    return args;
  }
}

// ---- MAJOR ---
// Streaming Kernel Logging Service
class LogcatService {
  // --- Sub
  // Private Logic Containers
  Process? _process;
  final _controller = StreamController<String>.broadcast();
  bool _isActive = false;

  // --- Sub
  // Public Accessors
  Stream<String> get logs => _controller.stream;
  bool get isActive => _isActive;

  // --- Sub
  // Execution Control
  Future<void> start({LogcatConfig? config}) async {
    if (_isActive) await stop();

    final cfg = config ?? LogcatConfig();
    final args = cfg.toArgs();

    try {
      // Comment: Initialize logcat process via superuser bridge
      _process = await Process.start('su', ['-c', 'logcat ${args.join(' ')}']);
      _isActive = true;

      // Comment: Binary to UTF-8 line transformation
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (!_controller.isClosed) {
          _controller.add(line);
        }
      });

      // Comment: Internal telemetry for logging errors
      _process!.stderr
          .transform(utf8.decoder)
          .listen((data) => logger.e("Logcat Error: $data"));
    } catch (e) {
      _controller.add("Failed to start logcat: $e");
      _isActive = false;
    }
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
    _isActive = false;
  }

  // --- Sub
  // Service Cleanup
  void dispose() {
    stop();
    _controller.close();
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final logcatServiceProvider = Provider((ref) {
  final service = LogcatService();
  ref.onDispose(() => service.dispose());
  return service;
});
