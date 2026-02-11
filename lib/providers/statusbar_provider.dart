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

// ---- MAJOR ---
// Global State for the Application Status Bar
class StatusBarState {
  final int pageIndex;
  final String title;

  const StatusBarState({
    required this.pageIndex,
    required this.title,
  });

  // --- State Modification
  StatusBarState copyWith({
    int? pageIndex,
    String? title,
  }) {
    return StatusBarState(
      pageIndex: pageIndex ?? this.pageIndex,
      title: title ?? this.title,
    );
  }
}

// ---- MAJOR ---
// Controller for Status Bar Logic and Navigation Context
class StatusBarNotifier extends Notifier<StatusBarState> {
  // --- Internal Configuration
  static final Map<int, String> _pageTitles = {
    0: "DASHBOARD",
    1: "TWEAKS",
    2: "ADD-ONS",
    3: "UTILITIES",
    4: "DEVICE INFO",
    5: "SETTINGS",
  };

  // --- Initialization
  @override
  StatusBarState build() {
    return const StatusBarState(pageIndex: 0, title: "DASHBOARD");
  }

  // --- Logic Handlers
  void updatePage(int index) {
    state = state.copyWith(
      pageIndex: index,
      title: _pageTitles[index] ?? "ROOTIFY",
    );
  }
}

// ---- MAJOR ---
// Global Provider Access
final statusBarProvider =
    NotifierProvider<StatusBarNotifier, StatusBarState>(StatusBarNotifier.new);
