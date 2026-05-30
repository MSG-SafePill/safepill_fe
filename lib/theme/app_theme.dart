import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF6FAFF);
  static const primary = Color(0xFF2F80ED);
  static const primaryLight = Color(0xFFEAF3FF);
  static const accent = Color(0xFF42D6C6);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFF5A623);
  static const navy = Color(0xFF0B1F4D);
  static const muted = Color(0xFF8A97A8);
  static const card = Colors.white;
  static const line = Color(0xFFE8EEF7);
}

class AppTextStyles {
  static const title = TextStyle(
    color: AppColors.navy,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const screenTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    color: AppColors.navy,
    fontSize: 14,
    height: 1.45,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    height: 1.35,
    letterSpacing: 0,
  );
}

class AppDecorations {
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static BoxDecoration card({double radius = 22}) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line.withValues(alpha: 0.65)),
      boxShadow: softShadow,
    );
  }

  static BoxDecoration blueGradient({double radius = 22}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        colors: [Color(0xFF58C7FF), AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.22),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
