import 'package:flutter/material.dart';

/// Central color palette for the Healthcare App.
///
/// Design intent:
/// - Trustworthy, calm, healthcare-oriented, government/public-service feel
/// - High contrast for rural / low-literacy users
/// - No neon, no excessive gradients
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────────────────────
  /// Deep teal — primary brand color, used on buttons, active indicators
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF1AA3A8);
  static const Color primaryDark = Color(0xFF095558);
  static const Color primaryContainer = Color(0xFFDFF5F6);

  // ── Secondary / Accent ───────────────────────────────────────────────────
  /// Warm amber — used on CTAs, highlights, badges
  static const Color secondary = Color(0xFFF0A500);
  static const Color secondaryLight = Color(0xFFFFC107);
  static const Color secondaryContainer = Color(0xFFFFF3CD);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECF4F4);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A2B35);
  static const Color textSecondary = Color(0xFF5A7184);
  static const Color textHint = Color(0xFF9BB0BE);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFC0392B);
  static const Color errorContainer = Color(0xFFFDEDEB);
  static const Color success = Color(0xFF27AE60);
  static const Color successContainer = Color(0xFFE8F8EF);
  static const Color warning = Color(0xFFE67E22);

  // ── Role Colors (subtle accent per role card) ─────────────────────────────
  static const Color rolePatient = Color(0xFF1565C0);
  static const Color rolePatientLight = Color(0xFFE3F0FD);
  static const Color roleAsha = Color(0xFF2E7D32);
  static const Color roleAshaLight = Color(0xFFE8F5E9);
  static const Color roleDoctor = Color(0xFF0D7377);
  static const Color roleDoctorLight = Color(0xFFDFF5F6);
  static const Color roleAdmin = Color(0xFF6A1B9A);
  static const Color roleAdminLight = Color(0xFFF3E5F5);

  // ── Borders / Dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFFCFDEE4);
  static const Color divider = Color(0xFFE8F0F2);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A0D4F52);
}
