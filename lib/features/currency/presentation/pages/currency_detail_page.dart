import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/egp_trend.dart';
import '../../domain/entities/exchange_rate.dart';
import '../bloc/currency_detail/currency_detail_bloc.dart';
import '../widgets/seven_day_chart.dart';

class CurrencyDetailPage extends StatelessWidget {
  const CurrencyDetailPage({super.key, required this.rate});

  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CurrencyDetailBloc>(param1: rate)..add(const HistoryRequested()),
      child: _CurrencyDetailView(rate: rate),
    );
  }
}

class _CurrencyDetailView extends StatelessWidget {
  const _CurrencyDetailView({required this.rate});

  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${rate.code} / EGP'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(rate: rate),
            const SizedBox(height: 20),
            const _ChartSection(),
          ],
        ),
      ),
    );
  }
}

// ── Header card ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.rate});

  final ExchangeRate rate;

  @override
  Widget build(BuildContext context) {
    final changeColor = _changeColor(rate.egpTrend);
    final hasChange = rate.egpTrend != EgpTrend.unknown;
    final sign = rate.absoluteDelta >= 0 ? '+' : '';
    final deltaDecimals = rate.rate < 1.0 ? 4 : 2;
    // Drop the "24h" suffix when the percentage rounds to zero — same
    // threshold as ChangeBadge.isHidden so both surfaces are consistent.
    final deltaRoundsToZero = rate.percentDelta.abs() < 0.005;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Currency label ──────────────────────────────────────────
            Text(
              rate.name,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),

            // ── Rate (large) ────────────────────────────────────────────
            Text(
              _formatRate(rate.rate),
              style: AppTheme.numeric(
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'EGP per 1 ${rate.code}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),

            // ── 24h change (hidden for unknown) ────────────────────────
            if (hasChange) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    _trendIcon(rate.egpTrend),
                    color: changeColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$sign${rate.absoluteDelta.toStringAsFixed(deltaDecimals)}  '
                    '$sign${rate.percentDelta.toStringAsFixed(2)}%'
                    '${deltaRoundsToZero ? '' : '  24h'}',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],

            // ── Rate date ───────────────────────────────────────────────
            const SizedBox(height: 10),
            Text(
              _formatDate(rate.rateDate),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// stronger → trend_up (green): EGP gained value.
  /// weaker → trend_down (red): EGP lost value.
  /// The icon reflects EGP's direction, NOT the raw rate's direction.
  static IconData _trendIcon(EgpTrend trend) => switch (trend) {
        EgpTrend.stronger => Icons.trending_up_rounded,
        EgpTrend.weaker => Icons.trending_down_rounded,
        EgpTrend.unchanged => Icons.trending_flat_rounded,
        EgpTrend.unknown => Icons.remove,
      };

  static Color _changeColor(EgpTrend trend) => switch (trend) {
        EgpTrend.stronger => AppTheme.green,
        EgpTrend.weaker => AppTheme.red,
        EgpTrend.unchanged => AppTheme.textSecondary,
        EgpTrend.unknown => Colors.transparent,
      };

  static String _formatRate(double rate) =>
      rate < 1.0 ? rate.toStringAsFixed(4) : rate.toStringAsFixed(2);

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Chart section ──────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  const _ChartSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-Day History',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<CurrencyDetailBloc, CurrencyDetailState>(
          builder: (context, state) => switch (state.status) {
            CurrencyDetailStatus.initial ||
            CurrencyDetailStatus.loading =>
              const _ChartShimmer(),
            CurrencyDetailStatus.success =>
              SevenDayChart(history: state.history!),
            CurrencyDetailStatus.failure =>
              _ChartError(failure: state.failure!),
          },
        ),
      ],
    );
  }
}

// ── Chart states ───────────────────────────────────────────────────────────────

class _ChartShimmer extends StatelessWidget {
  const _ChartShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardSurface,
      highlightColor: const Color(0xFF252830),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Displayed inside the chart area so the header remains visible on failure.
class _ChartError extends StatelessWidget {
  const _ChartError({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              color: AppTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                failure.message,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
