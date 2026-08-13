import 'package:flutter/material.dart';

/// Official EDV brand palette — the single source of truth for color in the app.
///
/// Values mirror the admin panel theme (`edv-route-admin/src/styles.css`), which
/// derives from `docs/brand/logos oficial/Colores de EDV.pdf`. Keeping these in
/// sync guarantees the mobile app and the web panel are visually identical.
abstract final class AppColors {
  const AppColors._();

  // --- Brand red scale (700 and 900 are the official brand values) ---------
  static const Color primary50 = Color(0xFFFDF3F3);
  static const Color primary100 = Color(0xFFFBE2E2);
  static const Color primary200 = Color(0xFFF7C6C6);
  static const Color primary300 = Color(0xFFEF9A9A);
  static const Color primary400 = Color(0xFFE05C5C);
  static const Color primary500 = Color(0xFFC42B2B);
  static const Color primary600 = Color(0xFFA81212);
  static const Color primary700 = Color(0xFF920606); // official brand red
  static const Color primary800 = Color(0xFF7A0B0B);
  static const Color primary900 = Color(0xFF661212); // official dark red
  static const Color primary950 = Color(0xFF3F0808);
  static const Color primary = primary700;

  // --- Brand gold scale (400 is the official brand value) ------------------
  static const Color gold50 = Color(0xFFFDFAEC);
  static const Color gold100 = Color(0xFFFAF3D3);
  static const Color gold200 = Color(0xFFF5E6A6);
  static const Color gold300 = Color(0xFFEFD97E);
  static const Color gold400 = Color(0xFFEBCA54); // official brand gold
  static const Color gold500 = Color(0xFFE3B92E);
  static const Color gold600 = Color(0xFFC99E1D);
  static const Color gold700 = Color(0xFFA67F18);
  static const Color gold800 = Color(0xFF86651A);
  static const Color gold900 = Color(0xFF6E531A);
  static const Color gold = gold400;

  // --- Official brand gradient (brand red -> near black) -------------------
  static const Color gradientStart = primary700; // #920606
  static const Color gradientEnd = Color(0xFF1A0303);

  // --- Neutrals ------------------------------------------------------------
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280); // gray-500
  static const Color fieldBorder = Color(0xFF9CA3AF); // gray-400
  static const Color cardGrey = Color(0xFFEDEDED);
}
