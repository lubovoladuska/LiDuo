import 'package:flutter/material.dart';

/// Цветовая палитра "Степной модерн / Nomad Luxe"
/// Сочетает глубокий графит, благородное степное золото и бирюзовый индиго.
class AppColors {
  // Базовые темные тона (Graphite)
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF181B22);
  static const Color darkCard = Color(0xFF212530);
  static const Color darkCardElevated = Color(0xFF282D3B);
  static const Color darkBorder = Color(0xFF2F3646);

  // Базовые светлые тона (Luxe Cream)
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEFF1F5);
  static const Color lightBorder = Color(0xFFE2E5EB);

  // Акцентное золото (Steppe Gold)
  static const Color gold = Color(0xFFDCA542);
  static const Color goldLight = Color(0xFFF5C768);
  static const Color goldDark = Color(0xFFB57E24);
  static const Color goldMuted = Color(0x33DCA542);

  // Степной бирюзовый / индиго (Nomad Teal)
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealMuted = Color(0x260D9488);

  // Статусные цвета
  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0x2610B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0x26EF4444);

  // Текст
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // Адаптивные вспомогательные методы под активную тему
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMutedDark
        : textMutedLight;
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightSurface;
  }

  static Color cardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color goldAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldLight
        : const Color(0xFFB45309);
  }

  static Color tealAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? tealLight
        : tealDark;
  }

  static Color subtleContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withAlpha(60)
        : const Color(0xFFF1F5F9);
  }

  static Color transcriptionChip(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withAlpha(16)
        : const Color(0xFFE2E8F0);
  }
}
