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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import '../providers/shared_prefs_provider.dart';

// ---- MAJOR ---
// Theme Configuration Models
enum AppThemeMode { system, appDefault, light, dark }

enum AppBlurStyle { gaussian, mica, navy, liquid }

enum BlurCategory { card, toast, dock, overlay }

enum HeroBannerType { dynamic, asset, custom }

// ---- MAJOR ---
// Theme State Representation
class ThemeState {
  final AppThemeMode mode;
  final bool useMonet;
  final Color accentColor;
  final double blurSigma;
  final AppBlurStyle blurStyle;
  final bool enableBlurCards;
  final bool enableBlurDockStatus;
  final bool enableBlurToast;
  final HeroBannerType heroBannerType;
  final String? heroBannerPath;
  final bool isAdvancedBlurUnlocked;
  final bool isCardBlurWarningAccepted;

  const ThemeState({
    required this.mode,
    this.useMonet = false,
    required this.accentColor,
    this.blurSigma = 2.5,
    this.blurStyle = AppBlurStyle.liquid,
    this.enableBlurCards = false,
    this.enableBlurDockStatus = true,
    this.enableBlurToast = true,
    this.heroBannerType = HeroBannerType.dynamic,
    this.heroBannerPath,
    this.isAdvancedBlurUnlocked = false,
    this.isCardBlurWarningAccepted = false,
  });

  // --- Sub
  // Mutation Bridge
  ThemeState copyWith({
    AppThemeMode? mode,
    bool? useMonet,
    Color? accentColor,
    double? blurSigma,
    AppBlurStyle? blurStyle,
    bool? enableBlurCards,
    bool? enableBlurDockStatus,
    bool? enableBlurToast,
    HeroBannerType? heroBannerType,
    String? heroBannerPath,
    bool? isAdvancedBlurUnlocked,
    bool? isCardBlurWarningAccepted,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      useMonet: useMonet ?? this.useMonet,
      accentColor: accentColor ?? this.accentColor,
      blurSigma: blurSigma ?? this.blurSigma,
      blurStyle: blurStyle ?? this.blurStyle,
      enableBlurCards: enableBlurCards ?? this.enableBlurCards,
      enableBlurDockStatus: enableBlurDockStatus ?? this.enableBlurDockStatus,
      enableBlurToast: enableBlurToast ?? this.enableBlurToast,
      heroBannerType: heroBannerType ?? this.heroBannerType,
      heroBannerPath: heroBannerPath ?? this.heroBannerPath,
      isAdvancedBlurUnlocked:
          isAdvancedBlurUnlocked ?? this.isAdvancedBlurUnlocked,
      isCardBlurWarningAccepted:
          isCardBlurWarningAccepted ?? this.isCardBlurWarningAccepted,
    );
  }

  // --- Sub
  // State Conversion Helpers
  ThemeMode get flutterThemeMode {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.appDefault:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  // --- Sub
  // Gaussian Blur Logic Hub
  double getSigmaFor(BlurCategory category) =>
      shouldBlur(category) ? blurSigma : 0.0;

  bool shouldBlur(BlurCategory category) {
    switch (category) {
      case BlurCategory.card:
        return enableBlurCards;
      case BlurCategory.toast:
        return enableBlurToast;
      case BlurCategory.dock:
        return enableBlurDockStatus;
      case BlurCategory.overlay:
        return true;
    }
  }
}

// ---- MAJOR ---
// Theme State Controller
class ThemeNotifier extends Notifier<ThemeState> {
  // --- Sub
  // Persistence Keys
  static const _keyMode = 'theme_mode';
  static const _keyUseMonet = 'theme_use_monet';
  static const _keyAccent = 'theme_accent';
  static const _keyBlurSigma = 'theme_blur_sigma';
  static const _keyBlurStyle = 'theme_blur_style';
  static const _keyBlurCards = 'theme_blur_cards';
  static const _keyBlurDock = 'theme_blur_dock';
  static const _keyBlurToast = 'theme_blur_toast';
  static const _keyAdvancedUnlocked = 'theme_advanced_unlocked';
  static const _keyBlurWarningAccepted = 'theme_blur_warning_accepted';

  late SharedPreferences _prefs;
  Timer? _saveTimer;

  @override
  ThemeState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadSettings();
  }

  // --- Sub
  // Persistence Engine
  ThemeState _loadSettings() {
    final modeIndex = _prefs.getInt(_keyMode) ?? AppThemeMode.appDefault.index;
    final useMonet = _prefs.getBool(_keyUseMonet) ?? false;
    final accentValue = _prefs.getInt(_keyAccent) ?? 0xFF3B82F6;
    final sigma = _prefs.getDouble(_keyBlurSigma) ?? 2.5;
    final styleIndex =
        _prefs.getInt(_keyBlurStyle) ?? AppBlurStyle.liquid.index;

    return ThemeState(
      mode: AppThemeMode.values[modeIndex],
      useMonet: useMonet,
      accentColor: Color(accentValue),
      blurSigma: sigma,
      blurStyle: AppBlurStyle.values[styleIndex],
      enableBlurCards: _prefs.getBool(_keyBlurCards) ?? false,
      enableBlurDockStatus: _prefs.getBool(_keyBlurDock) ?? true,
      enableBlurToast: _prefs.getBool(_keyBlurToast) ?? true,
      heroBannerType:
          HeroBannerType.values[_prefs.getInt('theme_hero_banner_type') ?? 0],
      heroBannerPath: _prefs.getString('theme_hero_banner_path'),
      isAdvancedBlurUnlocked: _prefs.getBool(_keyAdvancedUnlocked) ?? false,
      isCardBlurWarningAccepted:
          _prefs.getBool(_keyBlurWarningAccepted) ?? false,
    );
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt(_keyMode, state.mode.index);
    await _prefs.setBool(_keyUseMonet, state.useMonet);
    await _prefs.setInt(_keyAccent, state.accentColor.toARGB32());
    await _prefs.setDouble(_keyBlurSigma, state.blurSigma);
    await _prefs.setInt(_keyBlurStyle, state.blurStyle.index);
    await _prefs.setBool(_keyBlurCards, state.enableBlurCards);
    await _prefs.setBool(_keyBlurDock, state.enableBlurDockStatus);
    await _prefs.setBool(_keyBlurToast, state.enableBlurToast);
    await _prefs.setInt('theme_hero_banner_type', state.heroBannerType.index);
    if (state.heroBannerPath != null) {
      await _prefs.setString('theme_hero_banner_path', state.heroBannerPath!);
    }
    await _prefs.setBool(_keyAdvancedUnlocked, state.isAdvancedBlurUnlocked);
    await _prefs.setBool(
        _keyBlurWarningAccepted, state.isCardBlurWarningAccepted);
  }

  // --- Sub
  // Synchronization Bridges
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      _saveSettings();
      _syncToOverlay();
    });
  }

  void _syncToOverlay() {
    FlutterOverlayWindow.shareData(
        {'accentColor': state.accentColor.toARGB32()});
  }

  // --- Sub
  // Mutation Logic
  void setMode(AppThemeMode mode) {
    if (mode == AppThemeMode.appDefault) {
      state = state.copyWith(
        mode: mode,
        useMonet: false,
        accentColor: const Color(0xFF3B82F6),
        blurSigma: 2.5,
        blurStyle: AppBlurStyle.liquid,
        enableBlurCards: false,
        enableBlurDockStatus: true,
        enableBlurToast: true,
      );
    } else {
      state = state.copyWith(mode: mode);
    }
    _saveSettings();
  }

  void setUseMonet(bool value) {
    _switchToDarkIfDefault();
    state = state.copyWith(useMonet: value);
    _saveSettings();
  }

  void setAccentColor(Color color) {
    _switchToDarkIfDefault();
    state = state.copyWith(accentColor: color, useMonet: false);
    _saveSettings();
  }

  void setBlurSigma(double sigma) {
    _switchToDarkIfDefault();
    state = state.copyWith(blurSigma: sigma);
    _debouncedSave();
  }

  void setBlurStyle(AppBlurStyle style) {
    _switchToDarkIfDefault();
    state = state.copyWith(blurStyle: style);
    _saveSettings();
  }

  void toggleBlurCards(bool value) {
    _switchToDarkIfDefault();
    state = state.copyWith(enableBlurCards: value);
    _saveSettings();
  }

  void toggleBlurDockStatus(bool value) {
    _switchToDarkIfDefault();
    state = state.copyWith(enableBlurDockStatus: value);
    _saveSettings();
  }

  void toggleBlurToast(bool value) {
    _switchToDarkIfDefault();
    state = state.copyWith(enableBlurToast: value);
    _saveSettings();
  }

  void setHeroBanner(HeroBannerType type, String? path) {
    state = state.copyWith(heroBannerType: type, heroBannerPath: path);
    _saveSettings();
  }

  void unlockAdvancedBlur() {
    state = state.copyWith(isAdvancedBlurUnlocked: true);
    _saveSettings();
  }

  void acceptCardBlurWarning() {
    state = state.copyWith(isCardBlurWarningAccepted: true);
    _saveSettings();
  }

  void _switchToDarkIfDefault() {
    if (state.mode == AppThemeMode.appDefault) {
      state = state.copyWith(mode: AppThemeMode.dark);
    }
  }
}

// ---- MAJOR ---
// Global Theme Provider
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
