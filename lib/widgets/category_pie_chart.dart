import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';

class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    required this.byCategory,
    required this.categoryById,
    super.key,
  });

  final Map<String, double> byCategory;
  final Map<String, Category> categoryById;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  final Set<String> _hidden = <String>{};
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> entries =
        widget.byCategory.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
              b.value.compareTo(a.value));

    final List<MapEntry<String, double>> visible = entries
        .where((MapEntry<String, double> e) => !_hidden.contains(e.key))
        .toList();
    final double visibleTotal =
        visible.fold(0, (double s, MapEntry<String, double> e) => s + e.value);

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('当前范围暂无支出数据')),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 240,
          child: visible.isEmpty
              ? const Center(child: Text('全部分类已隐藏'))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 56,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent e, PieTouchResponse? r) {
                        setState(() {
                          if (!e.isInterestedForInteractions ||
                              r == null ||
                              r.touchedSection == null) {
                            _touched = -1;
                            return;
                          }
                          _touched = r.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: List<PieChartSectionData>.generate(
                      visible.length,
                      (int i) {
                        final MapEntry<String, double> e = visible[i];
                        final Category? cat = widget.categoryById[e.key];
                        final Color color = cat != null
                            ? Color(cat.color)
                            : Theme.of(context).colorScheme.primary;
                        final bool isTouched = i == _touched;
                        final double pct = visibleTotal == 0
                            ? 0
                            : e.value / visibleTotal * 100;
                        return PieChartSectionData(
                          value: e.value,
                          color: color,
                          radius: isTouched ? 70 : 60,
                          title: isTouched
                              ? '${pct.toStringAsFixed(1)}%\n${Formatters.currency(e.value)}'
                              : '${pct.toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 12 : 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          titlePositionPercentageOffset: 0.6,
                        );
                      },
                    ),
                  ),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.map((MapEntry<String, double> e) {
            final Category? cat = widget.categoryById[e.key];
            final bool hidden = _hidden.contains(e.key);
            final Color color = cat != null
                ? Color(cat.color)
                : Theme.of(context).colorScheme.outline;
            return InputChip(
              label: Text(
                '${cat?.name ?? '未分类'}  ${Formatters.currency(e.value)}',
                style: TextStyle(
                  decoration: hidden ? TextDecoration.lineThrough : null,
                ),
              ),
              avatar: CircleAvatar(
                backgroundColor:
                    hidden ? Colors.grey : color.withValues(alpha: 0.85),
                child: Icon(
                  IconCatalog.resolve(cat?.icon ?? 'category'),
                  size: 14,
                  color: Colors.white,
                ),
              ),
              onPressed: () => setState(() {
                if (hidden) {
                  _hidden.remove(e.key);
                } else {
                  _hidden.add(e.key);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
