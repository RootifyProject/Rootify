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
import 'dart:ui';

// ---- MAJOR ---
// Rootify Master Palette - Neo-Glassmorphism
// Deep Slate backgrounds with Neon Blue accents for high-contrast technical precision.
class RootifyColors {
  // --- Sub
  // Dark Background Layer (Cyber-Slate)
  static const Color neoDarkBg = Color(0xFF0F172A);
  static const Color neoDarkCard = Color(0xFF1E293B);
  static const Color neoDarkAccent = Color(0xFF334155);

  // --- Sub
  // Light Background Layer (Pristine)
  static const Color neoLightBg = Color(0xFFF8FAFC);
  static const Color neoLightCard = Color(0xFFFFFFFF);
  static const Color neoLightAccent = Color(0xFFE2E8F0);

  // --- Sub
  // Primary Accents (Rootify Identity)
  static const Color primaryNeon = Color(0xFF5B8BFF);
  static const Color primaryGlow = Color(0xFF8FAEFF);
  static const Color primaryDeep = Color(0xFF4772E6);

  // --- Sub
  // Translucency & Glass Borders
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x0DFFFFFF);

  // --- Sub
  // Typography Colors
  static const Color textWhite = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF64748B);

  // --- Sub
  // Functional/Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // --- Sub
  // Legacy Aliases for Compatibility
  static const Color primary = primaryNeon;
  static const Color primaryBright = primaryGlow;
}

// ---- MAJOR ---
// Semantic Mapping for Dark Mode
class DarkColors {
  static const Color primary = RootifyColors.primaryNeon;
  static const Color primaryBright = RootifyColors.primaryGlow;
  static const Color background = RootifyColors.neoDarkBg;
  static const Color surface = RootifyColors.neoDarkCard;
  static const Color surfaceVariant = RootifyColors.neoDarkAccent;
  static const Color onBackground = RootifyColors.textWhite;
  static const Color onSurface = RootifyColors.textSecondary;
  static const Color border = RootifyColors.glassBorderDark;
  static const Color outline = Color(0xFF475569);

  static const Color success = RootifyColors.success;
  static const Color warning = RootifyColors.warning;
  static const Color error = RootifyColors.error;
  static const Color info = RootifyColors.info;
}

// ---- MAJOR ---
// Semantic Mapping for Light Mode
class LightColors {
  static const Color primary = RootifyColors.primaryNeon;
  static const Color primaryBright = RootifyColors.primaryGlow;
  static const Color background = RootifyColors.neoLightBg;
  static const Color surface = RootifyColors.neoLightCard;
  static const Color surfaceVariant = RootifyColors.neoLightAccent;
  static const Color onBackground = RootifyColors.textDark;
  static const Color onSurface = RootifyColors.textDarkSecondary;
  static const Color border = Color(0xFFE2E8F0);
  static const Color outline = Color(0xFFCBD5E1);

  static const Color success = RootifyColors.success;
  static const Color warning = RootifyColors.warning;
  static const Color error = RootifyColors.error;
  static const Color info = RootifyColors.info;
}
