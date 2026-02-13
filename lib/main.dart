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
import 'package:flutter/services.dart';
import 'dart:ui';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ---- LOCAL ---
import 'theme/theme_provider.dart';
import 'theme/core/light.dart';
import 'theme/core/dark.dart';
import 'providers/shared_prefs_provider.dart';
import 'screen/splashs/splash_screen.dart';
import 'screen/overlays/fpsmeter_overlay.dart';
import 'utils/app_logger.dart';
import 'services/app_tracker_service.dart';
import 'services/error_reporting_service.dart';
import 'animations/master_transition.dart';

// ---- MAJOR ---
// Primary Application Orchestrator
// Handles global initialization, hardware optimization, and root widget mounting.

// --- Sub
// Overlay Entry Point (Mica/Glass Overlays)
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "config.env");
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FpsMeterOverlay(),
    ),
  );
}

// --- Sub
// Global Provider Access (Critical for Background Reporting)
late final ProviderContainer globalContainer;

// --- Sub
// Main Entry Point (Main UI)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "config.env");

  final prefs = await SharedPreferences.getInstance();
  final debugEnabled = prefs.getBool('debug_enabled') ?? false;

  // Comment: 1. Initialize AppLogger first for diagnostic capture
  await AppLogger().init(debug: debugEnabled);

  // Comment: 2. Enforce Peak Performance Refresh Rates
  await _setOptimalDisplayMode();

  // Comment: 3. System UI Integration (Edge-to-Edge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Comment: 4. Initialize Global ProviderContainer
  globalContainer = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Comment: 5. Global Async Error Handling (Hooked to Telegram)
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e("Global Platform Error", error, stack);
    ErrorReportingService.handleStatic(error, stack);
    return true; // Error handled
  };

  runApp(
    UncontrolledProviderScope(
      container: globalContainer,
      child: const RootifyApp(),
    ),
  );
}

// ---- MAJOR ---
// Hardware Optimization Engine
Future<void> _setOptimalDisplayMode() async {
  try {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    if (supported.isEmpty) return;

    // Comment: Priority 1 - Absolute Highest Refresh Rate (Smoothness)
    supported.sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
    final DisplayMode highestRefresh = supported.first;

    // Comment: Priority 2 - Match Current Resolution (Minimize Aliasing)
    final List<DisplayMode> modesWithHighestRefresh = supported
        .where((m) => m.refreshRate == highestRefresh.refreshRate)
        .toList();

    final DisplayMode active = await FlutterDisplayMode.active;
    final DisplayMode selectedMode = modesWithHighestRefresh.firstWhere(
      (m) => m.width == active.width && m.height == active.height,
      orElse: () => highestRefresh,
    );

    await FlutterDisplayMode.setPreferredMode(selectedMode);
    logger.d("Display: Optimal mode locked -> ${selectedMode.refreshRate}Hz");
  } catch (e) {
    logger.e("DisplayMode: Optimization failed", e);
  }
}

// ---- MAJOR ---
// Root Application Widget (Stateful Theme Bridge)
class RootifyApp extends ConsumerWidget {
  const RootifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    // Comment: Activate Background Automation (Auto-Open FPS Meter, etc.)
    ref.watch(autoOverlayControllerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Rootify',
          debugShowCheckedModeBanner: false,

          // Comment: Synchronize Theming Engine
          theme: AppLightTheme.theme(
            themeState.accentColor,
            visualStyle: themeState.visualStyle,
            colorScheme: themeState.useMonet ? lightDynamic : null,
          ),
          darkTheme: AppDarkTheme.theme(
            themeState.accentColor,
            visualStyle: themeState.visualStyle,
            colorScheme: themeState.useMonet ? darkDynamic : null,
          ),
          themeMode: themeState.flutterThemeMode,

          onGenerateRoute: (settings) => null,
          home: const SplashScreen(),

          // Comment: Hook into UI-level errors with access to context & ref
          builder: (context, child) {
            final brightness = themeState.flutterThemeMode == ThemeMode.dark ||
                    (themeState.flutterThemeMode == ThemeMode.system &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark)
                ? Brightness.dark
                : Brightness.light;

            // Detail: Force global error catch for UI builder
            FlutterError.onError = (details) {
              FlutterError.presentError(details);
              ErrorReportingService.handle(
                  context, ref, details.exception, details.stack);
            };

            return MasterTransition(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  statusBarIconBrightness: brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarIconBrightness:
                      brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark,
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}

// ---- END OF FILE ---
// Rootify App - Rootify Projects - Aby - 2026
