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

// ---- LOCAL ---
import '../../services/error_reporting_service.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/toast.dart';
import '../../widgets/cards.dart';
import '../statusbar/statusbar.dart';
import '../../theme/rootify_background_provider.dart';

// ---- MAJOR ---
// Feedback & Bug Reporting Page
class FeedbackReportsPage extends ConsumerStatefulWidget {
  const FeedbackReportsPage({super.key});

  @override
  ConsumerState<FeedbackReportsPage> createState() =>
      _FeedbackReportsPageState();

  static void showDenyConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Icon(LucideIcons.heartHandshake, color: colorScheme.error),
              const SizedBox(width: 16),
              const Text("Are you sure?",
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text(
            "Reporting errors helps us identify and fix bugs much faster. Without logs, some issues might remain broken for a long time.\n\nWould you like to reconsider and help Rootify grow?",
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Text(
                "SURE, I DENY",
                style: TextStyle(
                    color: theme.hintColor, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("REPORT NOW"),
            ),
          ],
        );
      },
    );
  }
}

class _FeedbackReportsPageState extends ConsumerState<FeedbackReportsPage> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String _selectedCategory = "BUG";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) {
      RootifyToast.show(context, "Please enter your feedback", isError: true);
      return;
    }

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    try {
      final category =
          _selectedCategory == "BUG" ? "BUG REPORT" : "FEATURE REQUEST";
      final success =
          await ErrorReportingService.sendFeedback(ref, category, text);

      if (!mounted) return;

      setState(() => _isSending = false);

      if (success) {
        RootifyToast.show(
            context, "Feedback sent! Thank you for your support.");
        _controller.clear();
        // Defer navigation to avoid widget tree conflicts
        Future.microtask(() {
          if (mounted) Navigator.pop(context);
        });
      } else {
        RootifyToast.show(
          context,
          "Transmission failed. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      RootifyToast.show(
        context,
        "Error: ${e.toString()}",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDarkMode = theme.brightness == Brightness.dark;
    final autoReport = ref.watch(feedbackProvider).autoReportErrors;

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
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: RootifySubBackground(
          child: Stack(
            children: [
              // Main Content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topPadding + 100,
                  left: 24,
                  right: 24,
                  bottom: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(theme, colorScheme),
                      const SizedBox(height: 40),

                      // Category Selection
                      _buildCategorySelector(colorScheme),
                      const SizedBox(height: 24),

                      // Input Field
                      _buildInputField(colorScheme),
                      const SizedBox(height: 24),

                      // Auto Report Toggle
                      _buildAutoReportToggle(theme, colorScheme, autoReport),
                      const SizedBox(height: 32),

                      // Submit Button
                      _buildSubmitButton(colorScheme),
                      const SizedBox(height: 16),

                      // Info Card
                      _buildInfoCard(theme, colorScheme),
                    ],
                  ),
                ),
              ),

              // Status Bar
              Positioned(
                top: topPadding + 10,
                left: 0,
                right: 0,
                child: const SystemStatusBar(
                  title: "FEEDBACK & REPORTS",
                  showBackButton: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            LucideIcons.messageSquare,
            color: colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Help Us Improve",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Report bugs or suggest features to make Rootify better for everyone",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ColorScheme colorScheme) {
    return RootifySubCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryButton(
              "BUG",
              LucideIcons.bug,
              _selectedCategory == "BUG",
              colorScheme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCategoryButton(
              "FEATURE",
              LucideIcons.lightbulb,
              _selectedCategory == "FEATURE",
              colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    String label,
    IconData icon,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _isSending
            ? null
            : () {
                HapticFeedback.lightImpact();
                if (mounted) {
                  setState(() => _selectedCategory = label);
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(ColorScheme colorScheme) {
    return RootifySubCard(
      padding: const EdgeInsets.all(20),
      child: TextFormField(
        controller: _controller,
        enabled: !_isSending,
        maxLines: 8,
        maxLength: 500,
        style: const TextStyle(fontSize: 15, height: 1.5),
        decoration: InputDecoration(
          hintText: _selectedCategory == "BUG"
              ? "Describe the bug, steps to reproduce, expected behavior..."
              : "Describe your feature idea, how it would help, use cases...",
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          counterStyle: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter your feedback";
          }
          if (value.trim().length < 10) {
            return "Please provide more details (at least 10 characters)";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAutoReportToggle(
    ThemeData theme,
    ColorScheme colorScheme,
    bool autoReport,
  ) {
    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            LucideIcons.zap,
            size: 20,
            color: autoReport ? colorScheme.primary : theme.hintColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Auto-Report Errors",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Automatically send crash logs",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: autoReport,
            onChanged: _isSending
                ? null
                : (val) {
                    HapticFeedback.lightImpact();
                    ref.read(feedbackProvider.notifier).setAutoReport(val);
                  },
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSending ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isSending
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.send, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    "SUBMIT FEEDBACK",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return RootifySubCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privacy Notice",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Reports include device info and app logs. No personal data is collected. All feedback is sent securely via Telegram.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
