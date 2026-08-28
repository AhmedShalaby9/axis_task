import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';

/// Placeholder card shown during the initial load (before any data arrives).
/// Matches the height of a real [RateCard] so the layout doesn't jump.
class ShimmerRateCard extends StatelessWidget {
  const ShimmerRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardSurface,
      highlightColor: const Color(0xFF252830),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
