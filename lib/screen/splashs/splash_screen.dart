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
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import '../../services/shell_services.dart';
import '../../widgets/toast.dart';
import '../../theme/core/color.dart';
import '../pages/dashboard.dart';
import 'step1/root_permission_check.dart';
import 'step2/onboarding.dart';
import 'step4/loading.dart';

// ---- MAJOR ---
// Primary Splash Screen Entry Point
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

// ---- MAJOR ---
// Splash State & Navigation Logic
class _SplashScreenState extends ConsumerState<SplashScreen> {
  // --- Fields
  int _currentStep = -1;
  bool _isBlocked = false;
  bool _seenOnboarding = false;

  // --- Initialization
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // --- Sub
  // App Startup Sequence
  Future<void> _initApp() async {
    // Detail
    // Check Persistence/Onboarding First (Direct to Step 3 if done)
    final prefs = await SharedPreferences.getInstance();
    _seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (_seenOnboarding) {
      if (mounted) setState(() => _currentStep = 2);
      return;
    }

    // Detail
    // Check Root Compliance FIRST (Required for Cyber/Neon first run)
    final shell = ref.read(shellServiceProvider);
    final errorMsg = await shell.checkRootCompliance();

    if (errorMsg != null && mounted) {
      setState(() => _isBlocked = true);
      // Show Toast with long duration to ensure readability
      RootifyToast.show(context, errorMsg,
          isError: true, duration: const Duration(seconds: 10));
      return;
    }

    // Detail
    // If valid root and not seen onboarding, START SETUP FLOW
    if (mounted) setState(() => _currentStep = 0);
  }

  // --- Sub
  // Navigation Transitions
  void _goToOnboarding() {
    if (_isBlocked) return;
    setState(() => _currentStep = 1);
  }

  void _goToLoading() {
    if (_isBlocked) return;
    setState(() => _currentStep = 2);
  }

  void _goToDashboard() {
    if (_isBlocked) return;
    // Preload/cache check complete, navigate with smooth transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Dashboard(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    // Detail
    // Use dynamic theme only if onboarding is done,
    // otherwise use "Cyber/Neon" (Dark + Blue) for first run.
    final Color effectiveBg = _seenOnboarding
        ? theme.scaffoldBackgroundColor
        : RootifyColors.neoDarkBg;

    if (_isBlocked) {
      return Scaffold(backgroundColor: effectiveBg);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _seenOnboarding
            ? (brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark)
            : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: _seenOnboarding
            ? (brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark)
            : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: effectiveBg,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildStep(),
        ),
      ),
    );
  }

  // --- Sub
  // Step Content Switcher
  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return RootCheckPage(
          key: const ValueKey('step1'),
          onRootGranted: _goToOnboarding,
        );
      case 1:
        return OnboardingPage(
          key: const ValueKey('step2'),
          onFinished: _goToLoading,
        );
      case 2:
        return LoadingPage(
          key: const ValueKey('step3'),
          onFinished: _goToDashboard,
        );
      default:
        // Default initial loading state
        return const Center(
          child: CircularProgressIndicator(color: RootifyColors.primaryNeon),
        );
    }
  }
}
