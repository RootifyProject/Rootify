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
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import 'shared_prefs_provider.dart';

// ---- MAJOR ---
// Feedback & Reporting Configuration Provider
// Manages global settings for automated bug reporting and feedback preferences.

class FeedbackSettings {
  final bool autoReportErrors;

  FeedbackSettings({
    this.autoReportErrors = false,
  });

  FeedbackSettings copyWith({
    bool? autoReportErrors,
  }) {
    return FeedbackSettings(
      autoReportErrors: autoReportErrors ?? this.autoReportErrors,
    );
  }
}

class FeedbackNotifier extends Notifier<FeedbackSettings> {
  @override
  FeedbackSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    return FeedbackSettings(
      autoReportErrors: prefs.getBool('auto_report_errors') ?? false,
    );
  }

  // --- Sub
  // Preference Mutations
  Future<void> setAutoReport(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('auto_report_errors', value);
    state = state.copyWith(autoReportErrors: value);
  }
}

// Global Provider Instance
final feedbackProvider =
    NotifierProvider<FeedbackNotifier, FeedbackSettings>(() {
  return FeedbackNotifier();
});
