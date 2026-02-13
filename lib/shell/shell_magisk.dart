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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../shell/base_shell.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Bridge for Magisk Systemless Interface
class MagiskShellService extends BaseShellService {
  MagiskShellService(super.session);

  // --- Sub
  // Module Inquiry Logic
  Future<bool> isModuleInstalled(String moduleId) async {
    logger.d("MagiskShell: Verifying module residency -> $moduleId");
    try {
      final result = await exec(
          '[ -d /data/adb/modules/$moduleId ] && echo "true" || echo "false"',
          silent: true);
      return result.trim() == "true";
    } catch (e) {
      logger.e("MagiskShell: Residency check failed for $moduleId", e);
      return false;
    }
  }

  // --- Sub
  // Property Retrieval Logic
  Future<String> getModuleProp(String moduleId, String key) async {
    // Comment: Regex-based extraction of module.prop key-value pairs
    final val = await exec(
        'grep "^$key=" /data/adb/modules/$moduleId/module.prop | cut -d= -f2-',
        silent: true);
    return val.trim();
  }
}

// ---- MAJOR ---
// Global Providers
final magiskShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return MagiskShellService(session);
});
