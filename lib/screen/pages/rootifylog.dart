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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// ---- LOCAL ---
import '../../utils/app_logger.dart';
import '../../services/logcat_service.dart';
import '../statusbar/sb_logs.dart';
import '../../widgets/toast.dart';
import '../overlays/help_dialog.dart';

// ---- MAJOR ---
// Multi-buffer System Log Observer & Application Diagnostic Console
class RootifyLogPage extends ConsumerStatefulWidget {
  const RootifyLogPage({super.key});

  @override
  ConsumerState<RootifyLogPage> createState() => _RootifyLogPageState();
}

class _RootifyLogPageState extends ConsumerState<RootifyLogPage> {
  // ---- STATE VARIABLES ---
  final ScrollController _logScrollController = ScrollController();
  final List<String> _liveLogs = [];
  final List<String> _logcatLogs = [];

  StreamSubscription? _logSubscription;
  StreamSubscription? _logcatSubscription;
  bool _isLogcatMode = false;
  bool _isLogcatRunning = false;
  LogcatConfig _logcatConfig = LogcatConfig();

  final bool _autoScroll = true;
  Timer? _debounceTimer;

  // ---- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadLogSettings();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _logcatSubscription?.cancel();
    _debounceTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  // ---- DATA ENGINE ---

  Future<void> _loadLogSettings() async {
    final p = await SharedPreferences.getInstance();

    final debugEnabled = p.getBool('debug_enabled') ?? false;
    logger.isDebugEnabled = debugEnabled;

    setState(() {
      _logcatConfig = LogcatConfig(
        buffer: p.getString('logcat_buffer') ?? "all",
        level: p.getString('logcat_level') ?? "V",
        filter: p.getString('logcat_filter') ?? "",
        extraArgs: p.getString('logcat_extra_args') ?? "",
      );
    });

    _initLogs();
  }

  void _initLogs() async {
    final history = await logger.getLogs();
    if (!mounted) return;

    setState(() {
      final lines = history.split('\n').where((l) => l.isNotEmpty).toList();
      _liveLogs.addAll(
          lines.length > 200 ? lines.sublist(lines.length - 200) : lines);
    });

    _logSubscription = logger.logStream.listen((log) {
      if (!mounted) return;
      if (!_isLogcatMode) {
        setState(() {
          _liveLogs.add(log);
          if (_liveLogs.length > 200) _liveLogs.removeAt(0);
        });
        if (_autoScroll) _triggerScroll();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ---- LOGIC HANDLERS ---

  void _toggleLogcat(bool enable) async {
    if (enable) {
      setState(() => _isLogcatMode = true);
    } else {
      await _stopLogcat();
      setState(() => _isLogcatMode = false);
    }
  }

  Future<void> _startLogcat() async {
    final logcat = ref.read(logcatServiceProvider);
    HapticFeedback.mediumImpact();

    await logcat.start(config: _logcatConfig);
    _logcatSubscription?.cancel();
    _logcatSubscription = logcat.logs.listen((line) {
      if (!mounted) return;
      if (_isLogcatMode && _isLogcatRunning) {
        setState(() {
          _logcatLogs.add(line);
          if (_logcatLogs.length > 500) _logcatLogs.removeAt(0);
        });
        if (_autoScroll) _triggerScroll();
      }
    });
    setState(() => _isLogcatRunning = true);
  }

  Future<void> _stopLogcat() async {
    final logcat = ref.read(logcatServiceProvider);
    await logcat.stop();
    _logcatSubscription?.cancel();
    setState(() => _isLogcatRunning = false);
  }

  void _triggerScroll() {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _saveLogsToPath(String location) async {
    try {
      HapticFeedback.mediumImpact();
      final history = (_isLogcatMode ? _logcatLogs : _liveLogs).join('\n');
      String targetPath = "";

      if (location == 'internal') {
        final dir = await getExternalStorageDirectory();
        final logsDir = Directory('${dir!.path}/logs');
        if (!logsDir.existsSync()) logsDir.createSync(recursive: true);
        targetPath =
            '${logsDir.path}/${_isLogcatMode ? "logcat" : "rootify"}.log';
      } else {
        targetPath =
            '/storage/emulated/0/Download/${_isLogcatMode ? "logcat" : "rootify"}.log';
      }

      final file = File(targetPath);
      await file.writeAsString(history);

      if (mounted) {
        RootifyToast.show(context, "Logs saved to: $targetPath");
      }
    } catch (e) {
      if (mounted) {
        RootifyToast.show(context, "Failed to save logs: $e", isError: true);
      }
    }
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;
    final isLandscape = mq.orientation == Orientation.landscape;
    final terminalHeight = mq.size.height * (isLandscape ? 0.35 : 0.52);

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
        body: Stack(
          children: [
            // --- Sub
            // 1. Mirrored Dynamic Mesh Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -120,
                      left: -120,
                      child: Container(
                        width: 450,
                        height: 450,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.15),
                              colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(30, -30),
                          end: const Offset(-30, 30),
                          duration: 12.seconds),
                    ),
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.secondary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(-30, 30),
                          end: const Offset(30, -30),
                          duration: 10.seconds),
                    ),
                  ],
                ),
              ),
            ),

            // --- Sub
            // 2. Main Scrolling Content
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 85)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isLogcatMode ? "LOGCAT" : "APP LOGS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                children: [
                                  _ModeBtn(
                                    label: "APP",
                                    active: !_isLogcatMode,
                                    onTap: () => _toggleLogcat(false),
                                  ),
                                  _ModeBtn(
                                    label: "LOGCAT",
                                    active: _isLogcatMode,
                                    onTap: () => _toggleLogcat(true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_isLogcatMode)
                          _DebugToggle(
                            isActive: logger.isDebugEnabled,
                            onChanged: (val) async {
                              HapticFeedback.mediumImpact();
                              setState(() => logger.isDebugEnabled = val);
                              final p = await SharedPreferences.getInstance();
                              await p.setBool('debug_enabled', val);
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          height: terminalHeight,
                          child: _buildTerminalWindow()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms),
                        ),
                        const SizedBox(height: 24),
                        if (!_isLogcatMode) ...[
                          _LargeActionButton(
                            label: "CLEAR LOGS",
                            icon: LucideIcons.trash2,
                            color: colorScheme.error,
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              await logger.clearLogs();
                              setState(() => _liveLogs.clear());
                              if (context.mounted) {
                                RootifyToast.show(context, "Logs cleared");
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LargeActionButton(
                                  label: "COPY LOGS",
                                  icon: LucideIcons.copy,
                                  color: colorScheme.primary,
                                  onTap: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text: _liveLogs.join('\n')));
                                    HapticFeedback.lightImpact();
                                    if (context.mounted) {
                                      RootifyToast.show(
                                          context, "Logs copied to clipboard");
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LargeActionButton(
                                  label: "SAVE LOGS",
                                  icon: LucideIcons.save,
                                  color: colorScheme.secondary,
                                  onTap: () => _showSaveDialog(context),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LargeActionButton(
                                label: _isLogcatRunning
                                    ? "STOP LOGCAT"
                                    : "START LOGCAT",
                                icon: _isLogcatRunning
                                    ? LucideIcons.stopCircle
                                    : LucideIcons.playCircle,
                                color: _isLogcatRunning
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                onTap: () {
                                  if (_isLogcatRunning) {
                                    _stopLogcat();
                                  } else {
                                    _startLogcat();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _LargeActionButton(
                                      label: "SAVE LOGS",
                                      icon: LucideIcons.save,
                                      color: colorScheme.secondary,
                                      onTap: () => _showSaveDialog(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _LargeActionButton(
                                      label: "CONFIGURE",
                                      icon: LucideIcons.settings2,
                                      color: colorScheme.primary,
                                      onTap: () => _showLogcatFilter(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _LargeActionButton(
                                label: "CLEAR LOGCAT",
                                icon: LucideIcons.trash2,
                                color: colorScheme.error.withValues(alpha: 0.8),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _logcatLogs.clear());
                                  RootifyToast.show(context, "Logcat cleared");
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),

            // --- Sub
            // 3. Floating Feature Status Bar
            Positioned(
              top: topPadding + 10,
              left: 0,
              right: 0,
              child: const LogsStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildTerminalWindow() {
    final colorScheme = Theme.of(context).colorScheme;
    final logs = _isLogcatMode ? _logcatLogs : _liveLogs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            if (logs.isEmpty)
              Center(
                child: Text(
                  _isLogcatMode
                      ? (_isLogcatRunning
                          ? "Streaming logcat..."
                          : "Logcat ready. Configure and start.")
                      : "Waiting for logs...",
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ListView.builder(
              controller: _logScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return _LogTextItem(log: logs[index]);
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SAVE LOGS AS rootify.log",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            _SaveLocationTile(
              title: "Internal Data",
              subtitle: "android/data/com.aby.rootify/logs/",
              icon: LucideIcons.folder,
              onTap: () async {
                Navigator.pop(ctx);
                await _saveLogsToPath('internal');
              },
            ),
            const SizedBox(height: 12),
            _SaveLocationTile(
              title: "Downloads Folder",
              subtitle: "/storage/emulated/0/Download/",
              icon: LucideIcons.download,
              onTap: () async {
                Navigator.pop(ctx);
                await _saveLogsToPath('downloads');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogcatFilter(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LogcatFilterModal(
        initialConfig: _logcatConfig,
        onApply: (newConfig) async {
          setState(() {
            _logcatConfig = newConfig;
            _logcatLogs.clear();
          });
          if (_isLogcatRunning) {
            _startLogcat();
          }
        },
        onSave: (config) async {
          final p = await SharedPreferences.getInstance();
          await p.setString('logcat_buffer', config.buffer);
          await p.setString('logcat_level', config.level);
          await p.setString('logcat_filter', config.filter ?? "");
          await p.setString('logcat_extra_args', config.extraArgs ?? "");
        },
      ),
    );
  }
}

// ---- SUPPORTING WIDGETS ---

class _LogTextItem extends StatelessWidget {
  final String log;
  const _LogTextItem({required this.log});

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.white70;
    if (log.contains("[E]") || log.contains(" E ")) {
      textColor = Colors.redAccent;
    } else if (log.contains("[W]") || log.contains(" W ")) {
      textColor = Colors.orangeAccent;
    } else if (log.contains("[D]") || log.contains(" D ")) {
      textColor = Colors.blueAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        log,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontFamily: 'Monospace',
        ),
      ),
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DebugToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _DebugToggle({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.terminal,
                size: 16,
                color: isActive ? theme.colorScheme.primary : theme.hintColor,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VERBOSE LOGGING",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Capture detailed internal operation logs",
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: theme.colorScheme.primary,
            inactiveTrackColor:
                theme.colorScheme.outline.withValues(alpha: 0.2),
            inactiveThumbColor: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _SaveLocationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SaveLocationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogcatFilterModal extends StatefulWidget {
  final LogcatConfig initialConfig;
  final Function(LogcatConfig) onApply;
  final Function(LogcatConfig) onSave;

  const _LogcatFilterModal({
    required this.initialConfig,
    required this.onApply,
    required this.onSave,
  });

  @override
  State<_LogcatFilterModal> createState() => _LogcatFilterModalState();
}

class _LogcatFilterModalState extends State<_LogcatFilterModal> {
  late String _buffer;
  late String _level;
  late TextEditingController _filterController;
  late TextEditingController _extraController;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialConfig.buffer;
    _level = widget.initialConfig.level;
    _filterController =
        TextEditingController(text: widget.initialConfig.filter);
    _extraController =
        TextEditingController(text: widget.initialConfig.extraArgs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "LOGCAT CONFIGURATION",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
              "Buffer",
              _buffer,
              ["all", "main", "system", "events", "crash", "radio"],
              (v) => setState(() => _buffer = v!)),
          const SizedBox(height: 16),
          _buildDropdown(
              "Minimum Priority",
              _level,
              ["V", "D", "I", "W", "E", "F"],
              (v) => setState(() => _level = v!)),
          const SizedBox(height: 16),
          _buildTextField(
              "Tag Filter", _filterController, "e.g. ActivityManager:I"),
          const SizedBox(height: 16),
          _buildTextField("Extra Arguments", _extraController, "e.g. -v long"),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final config = LogcatConfig(
                      buffer: _buffer,
                      level: _level,
                      filter: _filterController.text,
                      extraArgs: _extraController.text,
                    );
                    widget.onApply(config);
                    widget.onSave(config);
                    Navigator.pop(context);
                  },
                  child: const Text("APPLY"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    final helpContent = _getHelpContent(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => HelpOverlay.show(context,
                  title: label,
                  description: helpContent['desc']!,
                  usage: helpContent['usage']!),
              child: Icon(LucideIcons.helpCircle,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          initialSelection: value,
          expandedInsets: EdgeInsets.zero,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerLowest),
            surfaceTintColor:
                WidgetStateProperty.all(theme.colorScheme.surface),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
          dropdownMenuEntries: items.map((i) {
            final isSelected = i == value;
            return DropdownMenuEntry(
              value: i,
              label: i,
              labelWidget: Text(
                i,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onSelected: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint) {
    final theme = Theme.of(context);
    final helpContent = _getHelpContent(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => HelpOverlay.show(context,
                  title: label,
                  description: helpContent['desc']!,
                  usage: helpContent['usage']!),
              child: Icon(LucideIcons.helpCircle,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 13),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _getHelpContent(String label) {
    switch (label) {
      case "Buffer":
        return {
          "desc":
              "Selects which log buffer to read from. 'all' is usually best for general debugging.",
          "usage": "main: App logs\nsystem: OS logs\nevents: System events"
        };
      case "Minimum Priority":
        return {
          "desc":
              "Filters logs by their importance. Recommended: 'I' (Info) or 'W' (Warning).",
          "usage": "V: Verbose (All)\nD: Debug\nI: Info\nW: Warning\nE: Error"
        };
      case "Tag Filter":
        return {
          "desc":
              "Show only logs that match a specific tag and priority level.",
          "usage": "ActivityManager:I\nMyAppTag:D\n*:S (Silence all others)"
        };
      case "Extra Arguments":
        return {
          "desc": "Advanced flags for the logcat command.",
          "usage":
              "-v time (Show timestamps)\n-b radio (Radio buffer)\n-c (Clear logs before start)"
        };
      default:
        return {"desc": "No description available.", "usage": "N/A"};
    }
  }
}
