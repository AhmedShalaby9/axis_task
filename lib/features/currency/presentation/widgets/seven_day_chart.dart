import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/rate_history.dart';

/// Smooth line chart for up to 7 days of X→EGP rate history.
/// Renders correctly with fewer than 7 points — the caller must not treat
/// a partial dataset as an error.
class SevenDayChart extends StatelessWidget {
  const SevenDayChart({super.key, required this.history});

  final RateHistory history;

  @override
  Widget build(BuildContext context) {
    final points = history.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      points.length,
      (i) => FlSpot(i.toDouble(), points[i].rate),
    );

    final rates = points.map((p) => p.rate).toList();
    final minRate = rates.reduce(min);
    final maxRate = rates.reduce(max);

    // Provide vertical padding so the line isn't clipped at the chart edge.
    // When all values are equal, fall back to a fixed offset.
    final range = maxRate - minRate;
    final vPad = range > 0 ? range * 0.18 : maxRate * 0.05;

    final gridInterval = range > 0 ? range / 3 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: minRate - vPad,
            maxY: maxRate + vPad,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AppTheme.green,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.green.withValues(alpha: 0.22),
                      AppTheme.green.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final date = points[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${date.day} ${_monthAbbr(date.month)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    // meta.min and meta.max are the padded chart extremes
                    // (minRate - vPad, maxRate + vPad). They don't align with
                    // our data interval ticks, so showing them risks collision
                    // with adjacent ticks. Skip them; all other values are
                    // genuine interval ticks spaced by gridInterval = range/3,
                    // which are guaranteed not to collide.
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _formatRate(value),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: gridInterval,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.05),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppTheme.cardSurface,
                tooltipBorder: const BorderSide(
                  color: Colors.white12,
                  width: 0.5,
                ),
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final date = points[spot.spotIndex].date;
                  return LineTooltipItem(
                    _formatRate(spot.y),
                    TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(
                        text: '\n${date.day} ${_monthAbbr(date.month)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRate(double rate) =>
      rate < 1.0 ? rate.toStringAsFixed(4) : rate.toStringAsFixed(2);

  static String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
