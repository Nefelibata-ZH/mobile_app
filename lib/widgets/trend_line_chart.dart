import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/statistics_provider.dart';
import '../utils/formatters.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({required this.points, super.key});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('当前范围暂无数据')),
      );
    }

    final List<FlSpot> incomeSpots = <FlSpot>[];
    final List<FlSpot> expenseSpots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < points.length; i++) {
      final TrendPoint p = points[i];
      incomeSpots.add(FlSpot(i.toDouble(), p.income));
      expenseSpots.add(FlSpot(i.toDouble(), p.expense));
      if (p.income > maxY) maxY = p.income;
      if (p.expense > maxY) maxY = p.expense;
    }
    if (maxY == 0) maxY = 100;
    final double yInterval = (maxY / 4).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: SizedBox(
        height: 260,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: yInterval,
                  getTitlesWidget: (double v, TitleMeta m) => Text(
                    v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1)}k'
                        : v.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval:
                      points.length > 6 ? (points.length / 6).ceilToDouble() : 1,
                  getTitlesWidget: (double v, TitleMeta m) {
                    final int i = v.toInt();
                    if (i < 0 || i >= points.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        Formatters.monthDay(points[i].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> spots) =>
                    spots.map((LineBarSpot s) {
                  final TrendPoint p = points[s.x.toInt()];
                  final bool isIncome = s.barIndex == 0;
                  return LineTooltipItem(
                    '${Formatters.date(p.date)}\n'
                    '${isIncome ? '收入' : '支出'} ${Formatters.currency(s.y)}',
                    TextStyle(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: <LineChartBarData>[
              LineChartBarData(
                spots: incomeSpots,
                color: AppColors.income,
                barWidth: 2.5,
                isCurved: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.income.withValues(alpha: 0.08),
                ),
              ),
              LineChartBarData(
                spots: expenseSpots,
                color: AppColors.expense,
                barWidth: 2.5,
                isCurved: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.expense.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
      ),
    );
  }
}
