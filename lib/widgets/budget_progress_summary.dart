import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../providers/budget_progress_provider.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';

/// Compact budget progress strip rendered on the home and statistics
/// screens. Always tracks the *current* month — budgets are a per-month
/// concept and the user's intent is to see this-month spend versus
/// this-month limits regardless of any other range selector on screen.
///
/// Renders an empty SizedBox when no total budget and no per-category
/// budgets are set, so callers can drop it in unconditionally.
class BudgetProgressSummary extends ConsumerWidget {
  const BudgetProgressSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BudgetMonth month = BudgetMonth.current();
    final BudgetProgress? total =
        ref.watch(totalBudgetProgressForMonthProvider(month));
    final List<BudgetProgress> rows =
        ref.watch(budgetProgressForMonthProvider(month));

    if (total == null && rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.savings, size: 18),
              const SizedBox(width: 6),
              Text(
                '本月预算',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/settings/budgets'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('管理'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (total != null) _BudgetProgressTile.total(progress: total),
          if (total != null && rows.isNotEmpty) const SizedBox(height: 8),
          if (rows.isNotEmpty) _CategoryBudgetList(rows: rows),
        ],
      ),
    );
  }
}

class _CategoryBudgetList extends ConsumerWidget {
  const _CategoryBudgetList({required this.rows});
  final List<BudgetProgress> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Category> map = ref.watch(categoryByIdProvider);
    return Column(
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 6),
          _BudgetProgressTile.category(
            progress: rows[i],
            category: map[rows[i].budget.categoryId],
          ),
        ],
      ],
    );
  }
}

class _BudgetProgressTile extends StatelessWidget {
  const _BudgetProgressTile._({
    required this.progress,
    required this.title,
    required this.icon,
    required this.accent,
  });

  factory _BudgetProgressTile.total({required BudgetProgress progress}) {
    return _BudgetProgressTile._(
      progress: progress,
      title: '总预算',
      icon: Icons.savings,
      accent: AppColors.balance,
    );
  }

  factory _BudgetProgressTile.category({
    required BudgetProgress progress,
    required Category? category,
  }) {
    return _BudgetProgressTile._(
      progress: progress,
      title: category?.name ?? '已删除分类',
      icon: category == null
          ? Icons.category
          : IconCatalog.resolve(category.icon),
      accent: category == null ? Colors.grey : Color(category.color),
    );
  }

  final BudgetProgress progress;
  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.ratio.clamp(0, 1).toDouble();
    final int pct = (progress.ratio * 100).round();
    final Color barColor = progress.isOver
        ? AppColors.expense
        : progress.isWarning
            ? Colors.orange
            : accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: barColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped == 0 ? null : clamped,
            minHeight: 8,
            backgroundColor: barColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '${Formatters.currency(progress.spent)} / ${Formatters.currency(progress.budget.amount)}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              progress.isOver
                  ? '超支 ${Formatters.currency(progress.spent - progress.budget.amount)}'
                  : '剩余 ${Formatters.currency(progress.remaining)}',
              style: TextStyle(
                fontSize: 11,
                color: barColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
