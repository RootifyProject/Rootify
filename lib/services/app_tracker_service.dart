/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 */

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'shell_services.dart';
import '../providers/shared_prefs_provider.dart';

// ---- MAJOR ---
// Background Service for Foreground App Monitoring
class AppTrackerService {
  final ShellService _shell;
  Timer? _timer;
  String? _lastPackage;

  final StreamController<String> _packageStream =
      StreamController<String>.broadcast();
  Stream<String> get packageStream => _packageStream.stream;

  AppTrackerService(this._shell);

  // --- Sub
  // Start Polling (Recommended: 2s interval to save battery)
  void startTracking() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 2), (_) => _pollForegroundApp());
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  // --- Internal Logic
  Future<void> _pollForegroundApp() async {
    try {
      // Comment: Optimized dumpsys query for minimal IPC overhead
      final output = await _shell
          .exec("dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'");

      // Detail: Extract package name using regex
      // Example: mCurrentFocus=Window{... com.android.settings/com.android.settings.Settings}
      final regExp = RegExp(r'([a-zA-Z0-9\._]+)\/');
      final match = regExp.firstMatch(output);

      if (match != null) {
        final currentPackage = match.group(1);
        if (currentPackage != null && currentPackage != _lastPackage) {
          _lastPackage = currentPackage;
          _packageStream.add(currentPackage);
        }
      }
    } catch (_) {
      // Silent fail for background polling
    }
  }

  void dispose() {
    stopTracking();
    _packageStream.close();
  }
}

// --- Providers
final appTrackerServiceProvider = Provider((ref) {
  final shell = ref.read(shellServiceProvider);
  final tracker = AppTrackerService(shell);
  ref.onDispose(() => tracker.dispose());
  return tracker;
});

final foregroundAppProvider = StreamProvider<String>((ref) {
  final tracker = ref.watch(appTrackerServiceProvider);
  tracker.startTracking();
  return tracker.packageStream;
});

// ---- MAJOR ---
// Provider to handle automatic overlay activation logic
final autoOverlayControllerProvider = Provider.autoDispose((ref) {
  final foregroundApp = ref.watch(foregroundAppProvider).asData?.value;
  final prefs = ref.watch(sharedPreferencesProvider);

  final autoOpen = prefs.getBool('overlay_auto_open') ?? false;
  final whitelist = prefs.getStringList('overlay_whitelist') ?? [];
  final isEnabled = prefs.getBool('overlay_enabled') ?? false;

  if (autoOpen && foregroundApp != null) {
    if (whitelist.contains(foregroundApp)) {
      if (!isEnabled) {
        // Comment: Automatically show if not already showing
        FlutterOverlayWindow.isActive().then((active) {
          if (!active) {
            FlutterOverlayWindow.showOverlay(
              enableDrag: true,
              overlayTitle: "Rootify",
              width: -2,
              height: -2,
            );
            prefs.setBool('overlay_enabled', true);
          }
        });
      }
    }
  }
});
