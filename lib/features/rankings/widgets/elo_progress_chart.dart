import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// A reusable ELO progression line chart widget.
///
/// Renders a line chart of ELO points over time with gradient fill,
/// interactive tooltips, and a current ELO badge.
///
/// Parameters:
///   - [data]: List of (label, elo) data points sorted chronologically.
///   - [currentElo]: The latest ELO value to display in the badge.
///   - [tierName]: Optional current tier name (e.g., "Tier C").
///   - [height]: Chart height (default 220).
///   - [onHistoryEmpty]: Optional widget to show when no data is available.
class EloProgressChart extends StatelessWidget {
  final List<(String, int)> data;
  final int currentElo;
  final String? tierName;
  final double height;
  final Widget? onHistoryEmpty;

  const EloProgressChart({
    super.key,
    required this.data,
    required this.currentElo,
    this.tierName,
    this.height = 220,
    this.onHistoryEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (data.isEmpty) {
      return onHistoryEmpty ??
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_outlined,
                      size: 40, color: colors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có dữ liệu biểu đồ ELO',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          );
    }

    final maxElo = data.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    final minElo = data.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final eloRange = (maxElo - minElo).clamp(50, 2000);
    final chartMinY = (minElo - eloRange * 0.1).round().toDouble();
    final chartMaxY = (maxElo + eloRange * 0.1).round().toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Title + Current ELO Badge ───────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 18, color: colors.success),
                const SizedBox(width: 6),
                Text(
                  'TIẾN TRÌNH ELO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 14, color: colors.warning),
                      const SizedBox(width: 5),
                      Text(
                        NumberFormat('#,###', 'vi_VN').format(currentElo),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (tierName != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '| $tierName',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Line Chart ─────────────────────────────────────────────
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartMaxY - chartMinY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colors.border.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (data.length / 4)
                          .ceilToDouble()
                          .clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[index].$1,
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: chartMinY,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.$2.toDouble());
                    }).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == data.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4 : 2,
                          color: isLast ? AppTheme.primary : colors.bgCard,
                          strokeWidth: isLast ? 2 : 1.5,
                          strokeColor: AppTheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.3),
                        AppTheme.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final label = index < data.length ? data[index].$1 : '';
                        return LineTooltipItem(
                          'ELO: ${spot.y.toInt()}\n$label',
                          TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generate mock ELO history data from a single current ELO value.
///
/// Useful when the real API endpoint is not available yet.
/// Produces 6 data points spanning the last few months.
List<(String label, int elo)> generateMockEloHistory(int currentElo) {
  final months = [
    'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
    'T7', 'T8', 'T9', 'T10', 'T11', 'T12',
  ];
  final now = DateTime.now();
  final currentMonth = now.month;

  final history = <(String, int)>[];
  var elo = (currentElo * 0.7).round(); // Start at 70% of current
  final step = ((currentElo - elo) / 6).round().clamp(1, 50);

  for (var i = 0; i < 6; i++) {
    final monthIndex = (currentMonth - 6 + i) % 12;
    final monthLabel = months[monthIndex >= 0 ? monthIndex : monthIndex + 12];
    elo += step + (i % 3 == 0 ? 10 : -5); // Some variation
    history.add((monthLabel, elo.clamp(100, 3000)));
  }
  // Ensure last point matches current ELO
  history.last = (months[(currentMonth - 1) % 12], currentElo);

  return history;
}
