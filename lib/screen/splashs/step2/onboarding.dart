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

// ---- EXTERNAL ---
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import '../../../widgets/buttons.dart';
import '../../../widgets/typography.dart';
import '../../../animations/splashscreen_animation.dart';

// ---- MAJOR ---
// Onboarding Experience Component
class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingPage({super.key, required this.onFinished});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

// ---- MAJOR ---
// Onboarding State & Carousel Logic
class _OnboardingPageState extends State<OnboardingPage> {
  // --- Fields
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _acceptedResponsibility = false;

  // --- Static Content
  final List<Map<String, dynamic>> _pages = _OnboardingData.pages;

  // --- Lifecycle
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Sub
  // Onboarding Completion Helper
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    widget.onFinished();
  }

  // --- Sub
  // Navigation Flow Management
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      if (_acceptedResponsibility) {
        _completeOnboarding();
      } else {
        // Detail: Show error if responsibility checkbox isn't checked
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please accept the responsibility to proceed.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final isLast = index == _pages.length - 1;
                  final isActive = index == _currentPage;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_controller.position.haveDimensions) {
                        value = _controller.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      }
                      return Center(
                        child: Opacity(
                          opacity: value,
                          child: Transform.scale(scale: value, child: child),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildVisualContent(page, primaryColor),
                          const SizedBox(height: 48),
                          SplashScreenAnimation.pageContentFade(
                            Text(
                              page['title']!,
                              style: RootifyTypography.adaptiveHeader(context),
                              textAlign: TextAlign.center,
                            ),
                            isActive,
                            delayMs: 200,
                          ),
                          const SizedBox(height: 16),
                          SplashScreenAnimation.pageContentFade(
                            Text(
                              page['body']!,
                              style: RootifyTypography.adaptiveBody(context),
                              textAlign: TextAlign.center,
                            ),
                            isActive,
                            delayMs: 400,
                          ),
                          if (isLast) ...[
                            const SizedBox(height: 40),
                            _buildResponsibilityCheckbox(
                                colorScheme, primaryColor, isActive),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildBottomBar(colorScheme, primaryColor),
          ],
        ),
      ),
    );
  }

  // --- Sub
  // Dynamic Content Components
  Widget _buildVisualContent(Map<String, dynamic> page, Color primaryColor) {
    final type = page['type'] as String;

    return SizedBox(
      width: 140,
      height: 140,
      child: switch (type) {
        'rocket_launch' => SplashScreenAnimation.rocketStanding(
            Icon(page['icon'] as IconData, size: 100, color: primaryColor),
          ),
        'drawing_sliders' => SplashScreenAnimation.movingSliders(
            primaryColor,
            const Size(140, 140),
          ),
        'rgb_light' => SplashScreenAnimation.lightRunning(
            Icon(page['icon'] as IconData, size: 80, color: primaryColor),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // --- Sub
  // Legal Responsibility Widget
  Widget _buildResponsibilityCheckbox(
      ColorScheme colorScheme, Color primaryColor, bool isActive) {
    return SplashScreenAnimation.checkboxCardSlideIn(
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => setState(
              () => _acceptedResponsibility = !_acceptedResponsibility),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedResponsibility,
                  onChanged: (val) =>
                      setState(() => _acceptedResponsibility = val ?? false),
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Text(
                    'I accept full responsibility for any changes made to my device.',
                    style: RootifyTypography.adaptiveBody(context)
                        .copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isActive,
    );
  }

  // --- Sub
  // Bottom Controls & Indicators
  Widget _buildBottomBar(ColorScheme colorScheme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_pages.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: isActive ? 32 : 8,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.6)
                        ])
                      : null,
                  color: isActive
                      ? null
                      : colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
              );
            }),
          ),
          PrimaryButton(
            onPressed:
                _currentPage == _pages.length - 1 && !_acceptedResponsibility
                    ? null
                    : _nextPage,
            label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
            icon: _currentPage == _pages.length - 1
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Static Content Data
class _OnboardingData {
  static const List<Map<String, dynamic>> pages = [
    {
      'icon': Icons.rocket_launch_rounded,
      'title': 'Welcome to Rootify',
      'body':
          'The ultimate system control center for your rooted Android device.',
      'type': 'rocket_launch',
    },
    {
      'title': 'Take Control',
      'body':
          'Fine-tune Your Device. Tweaking, Optimizing and Tuning made easy.',
      'type': 'drawing_sliders',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Safety Mechanism',
      'body':
          'Built-in rollback features protect your device from unstable configurations.',
      'type': 'rgb_light',
    },
    {
      'icon': Icons.warning_amber_rounded,
      'title': 'Disclaimer',
      'body':
          'Rootify modifies system files. While we take precautions, you are responsible for your device. Proceed at your own risk.',
      'type': 'rgb_light',
    },
  ];
}
