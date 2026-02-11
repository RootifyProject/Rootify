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
import 'dart:io';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Superuser State & Enumerations
enum RootStatus { granted, denied }

// ---- MAJOR ---
// Static Bridge for Superuser Privilege Management
class Superuser {
  Superuser._();

  // --- Sub
  // Cached State
  static bool _isRooted = false;
  static bool get isRooted => _isRooted;

  // --- Sub
  // Privilege Acquisition
  static Future<bool> requestAccess() async {
    logger.d("Superuser: Validating root privileges...");

    try {
      // Comment: Execute single-shot su check
      final result = await Process.run('su', ['-c', 'id']);
      _isRooted = result.exitCode == 0;

      if (_isRooted) {
        logger.i("Superuser: ACQUISITION SUCCESSFUL");
      } else {
        logger.w("Superuser: ACQUISITION DENIED (Code: ${result.exitCode})");
      }

      return _isRooted;
    } catch (e) {
      logger.e("Superuser: SU binary missing or corrupted", e);
      _isRooted = false;
      return false;
    }
  }

  // --- Sub
  // Validation Logic
  static Future<bool> validateStatus() async {
    try {
      final result = await Process.run('su', ['-c', 'exit 0']);
      _isRooted = result.exitCode == 0;
      return _isRooted;
    } catch (e) {
      _isRooted = false;
      return false;
    }
  }

  // --- Sub
  // One-off Execution
  static Future<ProcessResult> exec(String command) async {
    if (!_isRooted) {
      logger.w("Superuser: Execution rejected (No root)");
      return ProcessResult(0, 126, "", "Root access required");
    }
    return Process.run('su', ['-c', command]);
  }
}

// ---- MAJOR ---
// Global Providers
final rootAccessProvider = FutureProvider<RootStatus>((ref) async {
  final granted = await Superuser.requestAccess();
  return granted ? RootStatus.granted : RootStatus.denied;
});
