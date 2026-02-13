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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../../providers/shared_prefs_provider.dart';
import '../../services/shell_services.dart';
import '../../services/system_monitor.dart';
import '../../utils/app_logger.dart';
import '../overlays/overlay_controller.dart';
import '../statusbar/sb_fpsmeter.dart';
import '../../widgets/cards.dart';
import '../../services/app_tracker_service.dart';
import '../../widgets/toast.dart';
import '../../theme/rootify_background_provider.dart';

// ---- MAJOR ---
// Performance Monitoring & FPS Meter Configuration Page
// --- FpsMeterPage
class FpsMeterPage extends ConsumerStatefulWidget {
  const FpsMeterPage({super.key});

  @override
  ConsumerState<FpsMeterPage> createState() => _FpsMeterPageState();
}

class _FpsMeterPageState extends ConsumerState<FpsMeterPage>
    with WidgetsBindingObserver {
  // --- Sub
  // Active state of the overlay engine
  bool _isActive = false;

  // --- Sub
  // Lifecycle Management

  @override
  void initState() {
    super.initState();
    logger.d("FpsMeterPage: Initializing lifecycle observer");
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    logger.d("FpsMeterPage: Removing lifecycle observer");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d("FpsMeterPage: State transition -> $state");
    if (state == AppLifecycleState.resumed) {
      // Warm up shell and refresh monitoring
      ref.read(shellServiceProvider).warmup();
      ref.invalidate(systemMonitorProvider);
    } else if (state == AppLifecycleState.paused) {
      // Clean up shell session to save battery
      ref.read(shellServiceProvider).killSession();
    }
  }

  // --- Sub
  // Event Handlers

  Future<void> _checkStatus() async {
    final status = await FlutterOverlayWindow.isActive();
    if (mounted) {
      // Detail: Synchronize local state with overlay engine
      setState(() => _isActive = status);
    }
  }

  // ---- MAJOR ---
  // UI Builder

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Contextual Layout
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RootifySubBackground(
          child: Stack(
            children: [
              // --- Sub
              // Scrolling content layer
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Space
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),

                  // Feature Hero Icon
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          // --- Sub
                          // Branded hero icon with glow
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Icon(LucideIcons.activity,
                                size: 48, color: colorScheme.primary),
                          ).animate().scale(
                              duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 16),
                          // Detail: Page title with tracking
                          Text(
                            "FPS METER",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: colorScheme.primary,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Functional Widgets
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader(context, "OVERLAY ENGINE"),
                        const SizedBox(height: 12),
                        _buildToggleCard(context),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, "AUTOMATION"),
                        const SizedBox(height: 12),
                        _buildAutomationCard(context),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, "FEATURE OVERVIEW"),
                        const SizedBox(height: 12),
                        _buildFeatureGrid(context),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),

              // --- Sub
              // Floating status display
              Positioned(
                top: topPadding + 10,
                left: 0,
                right: 0,
                child: const FpsMeterStatusBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub
  // Helper Builders

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildToggleCard(BuildContext context) {
    // --- Sub
    // Shared Preferences Access
    final prefs = ref.watch(sharedPreferencesProvider);

    return RootifyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Detail: Display switch for technical overlay
          _buildActionRow(
            context,
            icon: LucideIcons.mousePointer2,
            title: _isActive ? "ACTIVE" : "INACTIVE",
            subtitle: "Global performance overlay visibility",
            value: _isActive,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) async {
              logger.i("FpsMeterPage: Toggle Overlay -> $val");
              ref
                  .read(sharedPreferencesProvider)
                  .setBool('overlay_enabled', val);
              if (val) {
                await OverlayController.show(context);
              } else {
                await OverlayController.hide();
              }
              setState(() => _isActive = val);
            },
          ),
          const Divider(height: 32, indent: 40),
          // Detail: Interaction lock for touch passthrough
          _buildActionRow(
            context,
            icon: LucideIcons.lock,
            title: "LOCK OVERLAY",
            subtitle: "Enable touch passthrough mode",
            value: prefs.getBool('overlay_locked') ?? false,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (val) async {
              logger.i("FpsMeterPage: Toggle Passthrough -> $val");
              await ref
                  .read(sharedPreferencesProvider)
                  .setBool('overlay_locked', val);
              await OverlayController.toggleLock(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(sharedPreferencesProvider);
    final autoOpen = prefs.getBool('overlay_auto_open') ?? false;
    final whitelist = prefs.getStringList('overlay_whitelist') ?? [];

    return RootifyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionRow(
            context,
            icon: LucideIcons.bot,
            title: "AUTO-OPEN",
            subtitle: "Show overlay automatically for whitelisted apps",
            value: autoOpen,
            activeColor: const Color(0xFFA855F7),
            onChanged: (val) {
              ref
                  .read(sharedPreferencesProvider)
                  .setBool('overlay_auto_open', val);
              setState(() {});
            },
          ),
          const Divider(height: 32, indent: 40),
          // --- Sub
          // Whitelist management interface
          Row(
            children: [
              const Icon(LucideIcons.listTodo, size: 18, color: Colors.white70),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "WHITELISTED GAMES",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: () {
                  final foregroundApp =
                      ref.read(foregroundAppProvider).asData?.value;
                  if (foregroundApp != null) {
                    _addToWhitelist(foregroundApp);
                  } else {
                    RootifyToast.show(context, "Waiting for app detection...");
                  }
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          if (whitelist.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: whitelist
                  .map((pkg) => Chip(
                        label: Text(pkg, style: const TextStyle(fontSize: 10)),
                        onDeleted: () => _removeFromWhitelist(pkg),
                        backgroundColor: Colors.white12,
                        deleteIconColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ))
                  .toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("No apps whitelisted yet",
                  style: TextStyle(fontSize: 11, color: Colors.white30)),
            ),
        ],
      ),
    );
  }

  void _addToWhitelist(String pkg) {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList('overlay_whitelist') ?? [];
    if (!list.contains(pkg)) {
      list.add(pkg);
      prefs.setStringList('overlay_whitelist', list);
      RootifyToast.show(context, "Added $pkg to whitelist");
      setState(() {});
    }
  }

  void _removeFromWhitelist(String pkg) {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList('overlay_whitelist') ?? [];
    if (list.remove(pkg)) {
      prefs.setStringList('overlay_whitelist', list);
      setState(() {});
    }
  }

  Widget _buildActionRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required Color activeColor,
      required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                (value ? activeColor : theme.hintColor).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18, color: value ? activeColor : theme.hintColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: value
                          ? activeColor
                          : theme.textTheme.bodyLarge?.color)),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: theme.hintColor)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      children: [
        _buildFeatureItem(context, LucideIcons.gauge, "Real-time Delta",
            "High frequency frame tracking for precision data."),
        const SizedBox(height: 16),
        _buildFeatureItem(context, LucideIcons.barChart4, "Stat Aggregation",
            "Consolidated hardware metrics in a single floating view."),
      ],
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    return RootifySubCard(
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc,
                    style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
