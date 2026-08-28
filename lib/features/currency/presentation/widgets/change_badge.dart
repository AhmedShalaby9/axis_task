import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/egp_trend.dart';

/// Colored pill showing the 24-hour direction label, absolute delta,
/// and percentage change.
///
/// Hidden (returns [SizedBox.shrink]) when:
///   - [trend] is [EgpTrend.unknown] — no data to display.
///   - |[percentDelta]| < 0.005 — rounds to zero at display precision.
///     Using the percentage (not the absolute delta) as the threshold
///     means currencies priced at different scales (e.g. JPY at 0.31 EGP
///     vs USD at 50 EGP) are judged by the same proportional criterion.
///
/// Callers that need to maintain layout height when the badge is hidden
/// should check [isHidden] and substitute a [SizedBox] of fixed height.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({
    super.key,
    required this.trend,
    required this.absoluteDelta,
    required this.percentDelta,
    required this.decimalPlaces,
  });

  final EgpTrend trend;
  final double absoluteDelta;
  final double percentDelta;

  /// Decimal places for the absolute delta display.
  /// Must match the precision used for the rate itself so "-0.00" never
  /// appears. Callers derive this from the rate magnitude:
  ///   rate < 1.0  →  4  (e.g. JPY: 0.3147 EGP/JPY, delta: -0.0007)
  ///   rate ≥ 1.0  →  2  (e.g. USD: 50.24 EGP/USD,  delta: -0.31)
  final int decimalPlaces;

  /// True when this widget would return [SizedBox.shrink].
  /// Expose this so callers (e.g. [RateCard]) can substitute a spacer
  /// without duplicating the threshold logic.
  static bool isHidden(EgpTrend trend, double percentDelta) =>
      trend == EgpTrend.unknown || percentDelta.abs() < 0.005;

  @override
  Widget build(BuildContext context) {
    if (isHidden(trend, percentDelta)) return const SizedBox.shrink();

    final color = _colorFor(trend);
    final sign = absoluteDelta >= 0 ? '+' : '';
    final pSign = percentDelta >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        '${_egpLabel(trend)}  '
        '$sign${absoluteDelta.toStringAsFixed(decimalPlaces)}  '
        '$pSign${percentDelta.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Contextual label so colour and sign are self-explanatory.
  /// "EGP ↑" = EGP strengthened (fewer EGP per unit = falling inverted rate).
  static String _egpLabel(EgpTrend trend) => switch (trend) {
        EgpTrend.stronger => 'EGP ↑',
        EgpTrend.weaker => 'EGP ↓',
        EgpTrend.unchanged || EgpTrend.unknown => '',
      };

  static Color _colorFor(EgpTrend trend) => switch (trend) {
        EgpTrend.stronger => AppTheme.green,
        EgpTrend.weaker => AppTheme.red,
        EgpTrend.unchanged => AppTheme.textSecondary,
        EgpTrend.unknown => Colors.transparent,
      };
}
