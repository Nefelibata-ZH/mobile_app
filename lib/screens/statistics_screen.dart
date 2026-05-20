import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/statistics_provider.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/trend_line_chart.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('统计'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.pie_chart), text: '分类占比'),
              Tab(icon: Icon(Icons.show_chart), text: '收支趋势'),
            ],
          ),
        ),
        body: Column(
          children: const <Widget>[
            _RangeChips(),
            _RangeSummary(),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _PieTab(),
                  _LineTab(),
                ],
              ),
            ),
            _InsightsBar(),
          ],
        ),
      ),
    );
  }
}

class _RangeChips extends ConsumerWidget {
  const _RangeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RangeSelection sel = ref.watch(rangeSelectionProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          ChoiceChip(
            label: const Text('本月'),
            selected: sel.preset == RangePreset.month,
            onSelected: (_) => ref.read(rangeSelectionProvider.notifier).state =
                const RangeSelection(preset: RangePreset.month),
          ),
          ChoiceChip(
            label: const Text('本年'),
            selected: sel.preset == RangePreset.year,
            onSelected: (_) => ref.read(rangeSelectionProvider.notifier).state =
                const RangeSelection(preset: RangePreset.year),
          ),
          ChoiceChip(
            label: Text(
              sel.preset == RangePreset.custom && sel.custom != null
                  ? '${Formatters.date(sel.custom!.start)} ~ ${Formatters.date(sel.custom!.end.subtract(const Duration(days: 1)))}'
                  : '自定义',
            ),
            selected: sel.preset == RangePreset.custom,
            onSelected: (_) async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked == null) return;
              ref.read(rangeSelectionProvider.notifier).state = RangeSelection(
                preset: RangePreset.custom,
                custom: DateRange(
                  picked.start,
                  picked.end.add(const Duration(days: 1)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeSummary extends ConsumerWidget {
  const _RangeSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Totals t = ref.watch(rangeTotalsProvider);
    final RangePreset preset = ref.watch(rangeSelectionProvider).preset;
    final String title = switch (preset) {
      RangePreset.month => '本月',
      RangePreset.year => '本年',
      RangePreset.custom => '自定义范围',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SummaryCard(
        title: title,
        income: t.income,
        expense: t.expense,
      ),
    );
  }
}

class _PieTab extends ConsumerStatefulWidget {
  const _PieTab();

  @override
  ConsumerState<_PieTab> createState() => _PieTabState();
}

class _PieTabState extends ConsumerState<_PieTab> {
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> data = _showExpense
        ? ref.watch(rangeExpenseByCategoryProvider)
        : ref.watch(rangeIncomeByCategoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: <Widget>[
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                label: Text('支出'),
                icon: Icon(Icons.trending_down),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('收入'),
                icon: Icon(Icons.trending_up),
              ),
            ],
            selected: <bool>{_showExpense},
            onSelectionChanged: (Set<bool> v) =>
                setState(() => _showExpense = v.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (!states.contains(WidgetState.selected)) return null;
                  return (_showExpense ? AppColors.expense : AppColors.income)
                      .withValues(alpha: 0.18);
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (!states.contains(WidgetState.selected)) return null;
                  return _showExpense ? AppColors.expense : AppColors.income;
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          CategoryPieChart(
            byCategory: data,
            categoryById: ref.watch(categoryByIdProvider),
          ),
        ],
      ),
    );
  }
}

class _LineTab extends ConsumerWidget {
  const _LineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _LegendDot(color: AppColors.income, label: '收入'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.expense, label: '支出'),
              ],
            ),
          ),
          TrendLineChart(points: ref.watch(rangeTrendProvider)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _InsightsBar extends ConsumerWidget {
  const _InsightsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RangeInsights insights = ref.watch(rangeInsightsProvider);
    final Map<String, Category> map = ref.watch(categoryByIdProvider);
    final Category? top =
        insights.topCategoryId == null ? null : map[insights.topCategoryId];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _InsightTile(
                icon: Icons.calendar_view_day,
                label: '日均支出',
                value: Formatters.currency(insights.dailyExpenseAvg),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InsightTile(
                icon: Icons.bolt,
                label: '最大单笔',
                value: Formatters.currency(insights.maxExpense),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InsightTile(
                icon: top != null
                    ? IconCatalog.resolve(top.icon)
                    : Icons.category,
                iconColor: top != null ? Color(top.color) : null,
                label: '常用分类',
                value: top?.name ?? '—',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final Color color =
        iconColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
