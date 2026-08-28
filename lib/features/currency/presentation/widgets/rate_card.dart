import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/exchange_rate.dart';
import 'change_badge.dart';

class RateCard extends StatelessWidget {
  const RateCard({super.key, required this.rate, required this.onTap});

  final ExchangeRate rate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.green.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left column: code + display name ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.code,
                      style: AppTheme.numeric(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rate.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Right column: rate + change badge ───────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRate(rate.rate),
                    style: AppTheme.numeric(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!ChangeBadge.isHidden(rate.egpTrend, rate.percentDelta))
                    ChangeBadge(
                      trend: rate.egpTrend,
                      absoluteDelta: rate.absoluteDelta,
                      percentDelta: rate.percentDelta,
                      decimalPlaces: rate.rate < 1.0 ? 4 : 2,
                    )
                  else
                    // Maintain vertical space so all cards have equal height.
                    const SizedBox(height: 20),
                ],
              ),

              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sub-1 rates (e.g. JPY: 0.3147 EGP) use 4 d.p. to stay meaningful.
  /// Rates ≥ 1 (e.g. USD: 50.24 EGP) use 2 d.p.
  static String _formatRate(double rate) =>
      rate < 1.0 ? rate.toStringAsFixed(4) : rate.toStringAsFixed(2);
}
