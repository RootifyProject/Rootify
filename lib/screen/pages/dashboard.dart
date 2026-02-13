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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../dock/dock.dart';
import '../statusbar/sb_dashboard.dart';
import '../widgets/cpumonitor.dart';
import '../../theme/rootify_background_provider.dart';
import '../../providers/statusbar_provider.dart';
import 'device_info.dart';
import 'tweaks.dart';
import 'addons.dart';
import 'utilities.dart';
import 'settings.dart';

// ---- MAJOR ---
// Main Application Shell & Navigation Dashboard
class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  // ---- STATE VARIABLES ---

  int _currentIndex = 0;
  bool _isMenuTapped = false;

  // ---- EVENT HANDLERS ---

  void _onDockTap(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _isMenuTapped = true;
      _currentIndex = index;
    });

    // Notify Status Bar of context change
    ref.read(statusBarProvider.notifier).updatePage(index);
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Context & Theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: RootifyMainBackground(
          child: Stack(
            children: [
              // --- Sub
              // 2. Main Workspace View
              Positioned.fill(
                child: _buildCurrentPage(context),
              ),

              // --- Sub
              // 3. Global Dashboard Status Bar
              Positioned(
                top: topPadding + 10,
                left: 0,
                right: 0,
                child: const DashboardStatusBar(),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(
                  begin: -0.2,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack),

              // --- Sub
              // 4. Floating Navigation Dock
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: RootifyDock(
                  selectedIndex: _currentIndex,
                  isTapped: _isMenuTapped,
                  onHomeTap: () => _onDockTap(0),
                  onTweaksTap: () => _onDockTap(1),
                  onAddonsTap: () => _onDockTap(2),
                  onUtilsTap: () => _onDockTap(3),
                  onDeviceInfoTap: () => _onDockTap(4),
                  onSettingsTap: () => _onDockTap(5),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(
                  begin: 0.5,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildCurrentPage(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return RepaintBoundary(
          key: const ValueKey('page_home'),
          child: _buildDashboardHome(context),
        );
      case 1:
        return const RepaintBoundary(
          key: ValueKey('page_tweaks'),
          child: TweaksPage(),
        );
      case 2:
        return const RepaintBoundary(
          key: ValueKey('page_addons'),
          child: AddonsPage(),
        );
      case 3:
        return const RepaintBoundary(
          key: ValueKey('page_utilities'),
          child: UtilitiesPage(),
        );
      case 4:
        return const RepaintBoundary(
          key: ValueKey('page_device_info'),
          child: DeviceInfoPage(),
        );
      case 5:
        return const RepaintBoundary(
          key: ValueKey('page_settings'),
          child: SettingsPage(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardHome(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('dashboard_home_scroll'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80, // Space for status bar
        bottom: 120, // Space for dock
        left: 16,
        right: 16,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CpuMonitor(),
        ],
      ),
    );
  }
}
