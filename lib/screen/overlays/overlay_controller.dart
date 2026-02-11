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
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import '../../widgets/toast.dart';
import '../../shell/shellsession.dart';
import '../../services/shell_services.dart';

// ---- MAJOR ---
// Overlay Controller Utility
class OverlayController {
  // --- Actions

  // --- Sub
  // Show Global Overlay
  static Future<void> show(BuildContext context) async {
    // Detail
    // 1. SILENT ROOT GRANT
    try {
      final shell = ShellService(ShellSession());
      await shell.exec("appops set com.aby.rootify SYSTEM_ALERT_WINDOW allow");
    } catch (_) {
      // Silent fallback
    }

    // Detail
    // 2. Check Permission
    final hasPerm = await FlutterOverlayWindow.isPermissionGranted();

    if (!hasPerm) {
      final granted = await FlutterOverlayWindow.requestPermission();
      if (granted != true) return;
    } else {
      if (context.mounted) {
        TopToast.show(context, "Root: Overlay Permission Granted");
      }
    }

    try {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Rootify",
        visibility: NotificationVisibility.visibilityPublic,
        flag: OverlayFlag.defaultFlag,
        width: -2, // wrap_content (Ultra minimal)
        height: -2, // wrap_content
      );

      // --- Detail
      // Initial state sync
      final prefs = await SharedPreferences.getInstance();
      final locked = prefs.getBool('overlay_locked') ?? false;
      await FlutterOverlayWindow.shareData({'locked': locked});

      if (context.mounted) {
        TopToast.show(context, "Global Overlay Active");
      }
    } catch (e) {
      // Silent failure
    }
  }

  // --- Sub
  // Toggle Lock Mode (Touch Passthrough)
  static Future<void> toggleLock(bool locked) async {
    try {
      await FlutterOverlayWindow.updateFlag(
        locked ? OverlayFlag.clickThrough : OverlayFlag.defaultFlag,
      );
      // Sync state to overlay child
      await FlutterOverlayWindow.shareData({'locked': locked});
    } catch (_) {}
  }

  // --- Sub
  // Hide Global Overlay
  static Future<void> hide() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }
}
