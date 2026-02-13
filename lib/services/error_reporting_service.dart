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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ---- LOCAL ---
import '../providers/feedback_provider.dart';
import '../widgets/toast.dart';
import '../screen/pages-sub/feedback_reports.dart';
import '../utils/app_logger.dart';
import 'telegram_services.dart';
import 'vendor.dart';
import '../main.dart';

// ---- MAJOR ---
// Global Error Dispatcher Service
// Orchestrates automated reporting vs interactive user confirmation for crashes.

class ErrorReportingService {
  // --- Sub
  // Primary Entry Point (Widget Level)
  static void handle(BuildContext context, WidgetRef ref, Object error,
      [StackTrace? stackTrace]) async {
    final feedbackSettings = ref.read(feedbackProvider);

    if (feedbackSettings.autoReportErrors) {
      // Detail: Silent background transmission
      _sendReport(error, stackTrace: stackTrace, ref: ref);
    } else {
      // Detail: Interactive notification with manual override
      _showInteractiveErrorToast(context, ref, error, stackTrace);
    }
  }

  // --- Sub
  // Static Entry Point (Global Level)
  // Used for background/platform errors where no ref or context is available.
  static void handleStatic(Object error, [StackTrace? stackTrace]) {
    try {
      // Access main.dart globalContainer
      // We must import main.dart (adding later)
      _sendReport(error, stackTrace: stackTrace);
    } catch (_) {}
  }

  // --- Sub
  // Dual-Target Reporter
  static Future<void> _sendReport(Object error,
      {StackTrace? stackTrace, WidgetRef? ref}) async {
    // 1. Resolve Provider Access
    // Prefer passed Ref, fallback to Global Container
    final vendor = await (ref != null
        ? ref.read(vendorInfoProvider.future)
        : globalContainer.read(vendorInfoProvider.future));

    final feedbackSettings = (ref != null
        ? ref.read(feedbackProvider)
        : globalContainer.read(feedbackProvider));

    // Safety: Only auto-report if enabled (for static calls)
    if (ref == null && !feedbackSettings.autoReportErrors) return;

    // 2. PUBLIC FORMAT (#Report Bugs, max 5 lines)
    final publicChatId = dotenv.get('TELEGRAM_CHAT_ID');
    final bugTopicId = int.tryParse(dotenv.get('TOPIC_REPORT_BUGS_ID'));

    final publicMsg = "#Report Bugs\n"
        "Error: ${error.toString().split('\n').first}\n"
        "Device: ${vendor.model}\n"
        "Status: Automated Crash Caught\n"
        "Technical logs sent to private dump.";

    // 3. PRIVATE FORMAT (#Error, detailed)
    final privateChatId = dotenv.get('PRIVATE_CHANNEL_ID');
    final dumpTopicId = int.tryParse(dotenv.get('TOPIC_DUMPS_PRIVATE_ID'));

    String locationInfo = "Unknown Location";
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n');
      if (lines.isNotEmpty) {
        locationInfo = lines.firstWhere((l) => l.contains('.dart'),
            orElse: () => lines.first);
      }
    }

    // 4. FETCH RECENT LOGS
    String recentLogs = "No logs available.";
    try {
      final logs = await logger.getLogs();
      if (logs.length > 2000) {
        recentLogs = "...[TRUNCATED]...\n${logs.substring(logs.length - 2000)}";
      } else {
        recentLogs = logs;
      }
    } catch (_) {}

    final privateMsg = "#Error\n"
        "Model: ${vendor.model}\n"
        "Codename: ${vendor.codename}\n"
        "Manufacturer: ${vendor.manufacturer}\n"
        "Platform: ${vendor.board}\n"
        "Kernel: ${vendor.kernel}\n"
        "Graphics: ${vendor.graphics}\n\n"
        "Error: $error\n"
        "At: $locationInfo\n\n"
        "Recent App Logs:\n$recentLogs\n\n"
        "Stack Trace Snippet:\n${stackTrace?.toString().split('\n').take(12).join('\n') ?? 'N/A'}";

    // Dispatch
    await TelegramService.sendMessage(publicMsg,
        chatId: publicChatId, messageThreadId: bugTopicId);
    await TelegramService.sendMessage(privateMsg,
        chatId: privateChatId, messageThreadId: dumpTopicId);
  }

  // --- Sub
  // Manual Report Dispatcher (Used by Feedback Page)
  static Future<bool> sendFeedback(
      WidgetRef ref, String category, String text) async {
    final vendor = await ref.read(vendorInfoProvider.future);

    // 1. PUBLIC FORMAT
    final publicChatId = dotenv.get('TELEGRAM_CHAT_ID');
    final topicId = category == "BUG REPORT"
        ? int.tryParse(dotenv.get('TOPIC_REPORT_BUGS_ID'))
        : int.tryParse(dotenv.get('TOPIC_FEATURE_REQUEST_ID'));

    final tag = category == "BUG REPORT" ? "#Report Bugs" : "#Feature Request";

    final publicMsg = "$tag\n"
        "From: User Feedback\n"
        "Device: ${vendor.model}\n"
        "Snippet: ${text.length > 80 ? '${text.substring(0, 77)}...' : text}\n"
        "Status: Manual Transmission";

    // 2. PRIVATE FORMAT
    final privateChatId = dotenv.get('PRIVATE_CHANNEL_ID');
    final dumpTopicId = int.tryParse(dotenv.get('TOPIC_DUMPS_PRIVATE_ID'));

    // 3. FETCH RECENT LOGS
    String recentLogs = "No logs available.";
    try {
      final logs = await logger.getLogs();
      if (logs.length > 2500) {
        recentLogs = "...[TRUNCATED]...\n${logs.substring(logs.length - 2500)}";
      } else {
        recentLogs = logs;
      }
    } catch (_) {}

    final privateMsg = "$tag (MANUAL FEEDBACK)\n"
        "Model: ${vendor.model}\n"
        "Codename: ${vendor.codename}\n"
        "Manufacturer: ${vendor.manufacturer}\n"
        "Platform: ${vendor.board}\n"
        "Kernel: ${vendor.kernel}\n"
        "Graphics: ${vendor.graphics}\n\n"
        "Content:\n$text\n\n"
        "Detailed App Logs:\n$recentLogs";

    final successPublic = await TelegramService.sendMessage(publicMsg,
        chatId: publicChatId, messageThreadId: topicId);
    final successPrivate = await TelegramService.sendMessage(privateMsg,
        chatId: privateChatId, messageThreadId: dumpTopicId);

    return successPublic || successPrivate;
  }

  // --- Sub
  // Manual Interaction flow
  static void _showInteractiveErrorToast(
      BuildContext context, WidgetRef ref, Object error,
      [StackTrace? stackTrace]) {
    RootifyToast.show(
      context,
      "An unexpected error occurred.",
      isError: true,
      duration: const Duration(seconds: 8),
      actions: [
        // Action: Deny Button (Triggers Confirmation Dialog)
        TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // Close toast first
            FeedbackReportsPage.showDenyConfirmation(context);
          },
          child: const Text(
            "DENY",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        // Action: Report Button (Direct execution)
        ElevatedButton(
          onPressed: () async {
            HapticFeedback.lightImpact();
            await _sendReport(error, stackTrace: stackTrace, ref: ref);
            if (context.mounted) {
              RootifyToast.success(context, "Error reported successfully.");
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("REPORT",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ],
    );
  }
}
