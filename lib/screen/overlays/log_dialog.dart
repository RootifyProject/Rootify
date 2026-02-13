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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:lucide_icons/lucide_icons.dart';

// ---- MAJOR ---
// Log Overlay Component
class LogOverlay extends StatefulWidget {
  // --- Fields
  final String title;
  final String logs;
  final VoidCallback onClose;
  final VoidCallback? onClear;
  final Future<String> Function()? onRefresh;

  const LogOverlay({
    super.key,
    required this.title,
    required this.logs,
    required this.onClose,
    this.onClear,
    this.onRefresh,
  });

  // --- Static Actions
  static Future<void> show(BuildContext context, String title, String logs,
      {VoidCallback? onClear, Future<String> Function()? onRefresh}) async {
    return showDialog(
      context: context,
      builder: (context) => LogOverlay(
        title: title,
        logs: logs,
        onClose: () => Navigator.pop(context),
        onClear: onClear,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

// ---- MAJOR ---
// Log Overlay State Implementation
class _LogOverlayState extends State<LogOverlay> {
  // --- Properties
  double _fontSize = 11.0;
  late String _currentLogs;
  bool _isDisposed = false;

  // --- Lifecycle
  @override
  void initState() {
    super.initState();
    _currentLogs = widget.logs;
    if (widget.onRefresh != null) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // --- Internal Logic
  void _startPolling() async {
    while (!_isDisposed) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isDisposed) break;
      final newLogs = await widget.onRefresh!();

      if (!_isDisposed && newLogs != _currentLogs) {
        setState(() {
          _currentLogs = newLogs;
        });
      }
    }
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(LucideIcons.fileText,
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Logs Content
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      reverse: true,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          _currentLogs.isEmpty
                              ? "Waiting for logs..."
                              : _currentLogs,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: _fontSize,
                            height: 1.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Font Size Control
              Row(
                children: [
                  Icon(LucideIcons.minus,
                      size: 14, color: Theme.of(context).hintColor),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: 8.0,
                        max: 20.0,
                        activeColor: Theme.of(context).primaryColor,
                        label: "Zoom",
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ),
                  ),
                  Icon(LucideIcons.plus,
                      size: 14, color: Theme.of(context).hintColor),
                ],
              ),
              const SizedBox(height: 12),

              // Detail
              // Footer Actions (Copy/Clear)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentLogs));
                      },
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: const Text("Copy"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (widget.onClear != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onClear!();
                          setState(() => _currentLogs = "");
                        },
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: const Text("Clear"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Action Close
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
