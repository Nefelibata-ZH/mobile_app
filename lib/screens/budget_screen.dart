import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../providers/budget_progress_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';
import '../widgets/budget_editor_sheet.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BudgetMonth month = ref.watch(selectedBudgetMonthProvider);
    final List<BudgetProgress> rows = ref.watch(budgetProgressProvider);
    final BudgetSummary summary = ref.watch(budgetSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: Column(
        children: <Widget>[
          _MonthSwitcher(month: month),
          if (rows.isNotEmpty) _SummaryCard(summary: summary),
          Expanded(
            child: rows.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext ctx, int i) =>
                        _BudgetCard(progress: rows[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BudgetEditorSheet(initial: null, month: month),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新建预算'),
      ),
    );
  }
}

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher({required this.month});
  final BudgetMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一月',
            onPressed: () => ref
                .read(selectedBudgetMonthProvider.notifier)
                .state = month.shift(-1),
          ),
          Expanded(
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(month.label,
                    style: Theme.of(context).textTheme.titleMedium),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(month.year, month.month),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    helpText: '选择月份',
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked == null) return;
                  ref.read(selectedBudgetMonthProvider.notifier).state =
                      BudgetMonth(year: picked.year, month: picked.month);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一月',
            onPressed: () => ref
                .read(selectedBudgetMonthProvider.notifier)
                .state = month.shift(1),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final Color color = summary.ratio > 1
        ? AppColors.expense
        : summary.ratio >= 0.8
            ? Colors.orange
            : AppColors.balance;
    final double ratio = summary.ratio.clamp(0, 1).toDouble();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('本月总预算',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (summary.overCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${summary.overCount} 项超支',
                      style: const TextStyle(
                          color: AppColors.expense, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio == 0 ? null : ratio,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('已用 ${Formatters.currency(summary.totalSpent)}'),
                Text('额度 ${Formatters.currency(summary.totalBudget)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.savings_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            const Text('本月还没有设置预算'),
            const SizedBox(height: 4),
            Text('点右下角「新建预算」给某个支出类别设额度',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.progress});
  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Category> map = ref.watch(categoryByIdProvider);
    final Category? cat = map[progress.budget.categoryId];
    final Color accent = cat == null ? Colors.grey : Color(cat.color);
    final IconData icon =
        cat == null ? Icons.category : IconCatalog.resolve(cat.icon);

    final double clamped = progress.ratio.clamp(0, 1).toDouble();
    final Color barColor = progress.isOver
        ? AppColors.expense
        : progress.isWarning
            ? Colors.orange
            : accent;

    final BudgetMonth month = ref.watch(selectedBudgetMonthProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BudgetEditorSheet(
            initial: progress.budget,
            month: month,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.18),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cat?.name ?? '已删除分类',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${Formatters.currency(progress.spent)} / ${Formatters.currency(progress.budget.amount)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '删除',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: clamped,
                  minHeight: 10,
                  backgroundColor: barColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _trailing(progress),
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trailing(BudgetProgress p) {
    final int pct = (p.ratio * 100).round();
    if (p.isOver) {
      return '已超支 ${Formatters.currency(p.spent - p.budget.amount)}（$pct%）';
    }
    return '剩余 ${Formatters.currency(p.remaining)}（$pct%）';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除预算'),
        content: const Text('删除后将不再追踪该类别的本月超支提醒。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref
          .read(budgetListProvider.notifier)
          .remove(progress.budget.id);
    }
  }
}
