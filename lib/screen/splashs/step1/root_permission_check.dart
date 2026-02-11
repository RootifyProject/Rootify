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
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../../../../shell/superuser.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/typography.dart';
import '../../../animations/splashscreen_animation.dart';

// ---- MAJOR ---
// Root Access Verification Page
class RootCheckPage extends ConsumerStatefulWidget {
  final VoidCallback onRootGranted;

  const RootCheckPage({super.key, required this.onRootGranted});

  @override
  ConsumerState<RootCheckPage> createState() => _RootCheckPageState();
}

// ---- MAJOR ---
// Root Check State Implementation
class _RootCheckPageState extends ConsumerState<RootCheckPage>
    with TickerProviderStateMixin {
  // --- Fields
  bool _checking = true;
  String _statusMessage = 'Checking for root access...';
  late AnimationController _glowController;

  // --- Initialization
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkRoot();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // --- Sub
  // Root Validation Logic
  Future<void> _checkRoot() async {
    setState(() => _checking = true);
    // Detail: Artificial delay for smooth UX transition
    await Future.delayed(const Duration(milliseconds: 800));

    final isRooted = await Superuser.validateStatus();

    if (mounted) {
      if (isRooted) {
        widget.onRootGranted();
      } else {
        setState(() {
          _checking = false;
          _statusMessage = 'Root access not detected.';
        });
      }
    }
  }

  // --- Sub
  // Request Superuser Permission
  Future<void> _requestRoot() async {
    setState(() => _checking = true);
    final granted = await Superuser.requestAccess();
    if (mounted) {
      if (granted) {
        widget.onRootGranted();
      } else {
        setState(() {
          _checking = false;
          _statusMessage =
              'Root access denied. Please grant access to proceed.';
        });
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Detail: Animated Shield Icon with Glow effect
                SplashScreenAnimation.glowingShield(
                  Icon(
                    Icons.shield_outlined,
                    size: 72,
                    color: primaryColor,
                  ),
                  _glowController,
                ),

                const SizedBox(height: 48),

                // Detail: Title with slide-in animation
                SplashScreenAnimation.titleSlideIn(
                  Text(
                    'Root Access Required',
                    style: RootifyTypography.adaptiveHeader(context),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Detail: Description with slide-in animation
                SplashScreenAnimation.descriptionSlideIn(
                  Text(
                    'Rootify requires superuser privileges to optimize system performance and manage advanced settings.',
                    style: RootifyTypography.adaptiveBody(context),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                if (_checking)
                  _buildLoadingState(primaryColor)
                else
                  _buildErrorState(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub
  // Loading Progress View
  Widget _buildLoadingState(Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        SplashScreenAnimation.pulsingStatus(
          Text(
            _statusMessage,
            style: RootifyTypography.adaptiveCaption(context)
                .copyWith(color: primaryColor),
          ),
        ),
      ],
    );
  }

  // --- Sub
  // Error Message and Grant Action
  Widget _buildErrorState(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Detail: Status Message in a warning card
        SplashScreenAnimation.warningCardSlideUp(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _statusMessage,
                    style: RootifyTypography.adaptiveCaption(context).copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Detail: Primary action button to request root
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Grant Root Access',
            onPressed: _requestRoot,
            icon: Icons.lock_open_rounded,
          ),
        ),
      ],
    );
  }
}
