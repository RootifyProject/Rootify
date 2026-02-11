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

// ---- LOCAL ---
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Persistent Root Shell Orchestrator
class ShellSession {
  // --- Sub
  // Singleton Pattern
  static final ShellSession _instance = ShellSession._internal();
  factory ShellSession() => _instance;
  ShellSession._internal();

  // --- Sub
  // Configuration Constants
  static const Duration _cmdTimeout = Duration(seconds: 15);

  // --- Sub
  // Process Lifecycle State
  Process? _process;
  StreamSubscription? _subscription;
  bool _isProcessing = false;
  bool _isRootAvailable = true;
  DateTime? _lastRootAttempt;

  // --- Sub
  // Execution Context
  final List<_ShellTask> _queue = [];
  StringBuffer? _buffer;
  Completer<String>? _activeCompleter;
  String? _activeMarker;

  // --- Sub
  // Public Execution Bridge
  Future<String> exec(String cmd, {bool canSkip = false}) async {
    // Comment: Congestion management to prevent UI jank during heavy polling
    if (canSkip && _queue.length > 5) {
      return "";
    }

    final completer = Completer<String>();
    _queue.add(_ShellTask(cmd, completer));
    _processQueue();

    return completer.future;
  }

  // --- Sub
  // Private Queue Processor
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final task = _queue.removeAt(0);

    try {
      await _ensureSessionAlive();

      if (_process == null) {
        task.completer.complete("");
        return;
      }

      _prepareExecutionState(task.completer);

      // Comment: Echo unique marker to detect command completion in stream
      final commandLine = "${task.cmd} 2>&1; echo $_activeMarker";
      _process!.stdin.writeln(commandLine);

      await task.completer.future.timeout(
        _cmdTimeout,
        onTimeout: () {
          if (!task.completer.isCompleted) {
            logger.e("ShellSession: Command TIMEOUT -> ${task.cmd.trim()}");
            _terminateSession();
            task.completer.complete("TIMEOUT_ERROR");
          }
          return "TIMEOUT_ERROR";
        },
      );
    } catch (e) {
      if (_process != null) {
        logger.e("ShellSession: Bridge failure", e);
      }
      if (!task.completer.isCompleted) task.completer.complete("");
    } finally {
      _resetState();
      if (_queue.isNotEmpty) Timer.run(_processQueue);
    }
  }

  // --- Sub
  // Lifecycle Management Utilities
  Future<void> _ensureSessionAlive() async {
    if (_process != null) return;

    // Comment: Throttled root acquisition to prevent "su" spam on denial
    if (!_isRootAvailable) {
      if (_lastRootAttempt != null &&
          DateTime.now().difference(_lastRootAttempt!) <
              const Duration(seconds: 30)) {
        return;
      }
    }

    try {
      _lastRootAttempt = DateTime.now();
      logger.d("ShellSession: Spawning secure su wrapper...");
      _process = await Process.start('su', []);
      _isRootAvailable = true;

      _subscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onDataReceived, onError: (e) {
        logger.e("ShellSession: stdout breakdown", e);
        _terminateSession();
      }, onDone: () {
        logger.i("ShellSession: stdout closed");
        _terminateSession();
      });

      _process!.stderr.drain();
    } catch (e) {
      _isRootAvailable = false;
      logger.e("ShellSession: Root access ('su') failed");
      _terminateSession();
    }
  }

  void _onDataReceived(String line) {
    if (_activeMarker != null && line.contains(_activeMarker!)) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(_buffer?.toString().trim() ?? "");
      }
    } else if (_isProcessing) {
      _buffer?.writeln(line);
    }
  }

  void _prepareExecutionState(Completer<String> completer) {
    _buffer = StringBuffer();
    _activeCompleter = completer;
    _activeMarker = "EOF_${DateTime.now().microsecondsSinceEpoch}";
  }

  void _resetState() {
    _buffer = null;
    _activeCompleter = null;
    _activeMarker = null;
    _isProcessing = false;
  }

  void _terminateSession() {
    _subscription?.cancel();
    _process?.kill();
    _process = null;
    _subscription = null;
    _isProcessing = false;
  }

  void dispose() => _terminateSession();
}

// ---- MAJOR ---
// Private Task Wrapper
class _ShellTask {
  final String cmd;
  final Completer<String> completer;
  const _ShellTask(this.cmd, this.completer);
}
