import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import 'budget_provider.dart';
import 'expense_provider.dart';

/// Sentinel categoryId reserved for the per-month *total* budget. Stored
/// inside the existing Hive box so we don't have to migrate the schema.
const String kTotalBudgetCategoryId = '__total__';

class BudgetMonth {
  const BudgetMonth({required this.year, required this.month});
  final int year;
  final int month;

  static BudgetMonth current() {
    final DateTime now = DateTime.now();
    return BudgetMonth(year: now.year, month: now.month);
  }

  BudgetMonth shift(int delta) {
    final int total = month - 1 + delta;
    final int y = year + (total >= 0 ? total ~/ 12 : ((total - 11) ~/ 12));
    final int m = ((total % 12) + 12) % 12 + 1;
    return BudgetMonth(year: y, month: m);
  }

  DateTime get start => DateTime(year, month);
  DateTime get end => DateTime(year, month + 1);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  String get label => '$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is BudgetMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final StateProvider<BudgetMonth> selectedBudgetMonthProvider =
    StateProvider<BudgetMonth>((Ref ref) => BudgetMonth.current());

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
  });

  final Budget budget;
  final double spent;

  double get remaining => budget.amount - spent;
  double get ratio => budget.amount <= 0 ? 0 : spent / budget.amount;
  bool get isOver => spent > budget.amount;
  bool get isWarning => !isOver && ratio >= 0.8;
}

/// Per-category budget rows for an arbitrary month. Sorted with over-budget
/// first, then by descending spend ratio so the most urgent rows surface.
final ProviderFamily<List<BudgetProgress>, BudgetMonth>
    budgetProgressForMonthProvider =
    Provider.family<List<BudgetProgress>, BudgetMonth>((Ref ref, BudgetMonth m) {
  final List<Budget> budgets = ref
      .watch(budgetListProvider)
      .where((Budget b) =>
          b.year == m.year &&
          b.month == m.month &&
          b.categoryId != kTotalBudgetCategoryId)
      .toList();
  if (budgets.isEmpty) return const <BudgetProgress>[];

  final List<Expense> expenses = ref.watch(expenseListProvider);
  final Map<String, double> spentByCat = <String, double>{};
  for (final Expense e in expenses) {
    if (e.amount >= 0) continue;
    if (!m.contains(e.date)) continue;
    spentByCat.update(
      e.category,
      (double v) => v + -e.amount,
      ifAbsent: () => -e.amount,
    );
  }

  final List<BudgetProgress> result = budgets
      .map(
        (Budget b) => BudgetProgress(
          budget: b,
          spent: spentByCat[b.categoryId] ?? 0,
        ),
      )
      .toList()
    ..sort((BudgetProgress a, BudgetProgress b) {
      if (a.isOver != b.isOver) return a.isOver ? -1 : 1;
      return b.ratio.compareTo(a.ratio);
    });
  return result;
});

/// Total-month-budget row for an arbitrary month. Returns null when the
/// user hasn't set a total budget for that month.
final ProviderFamily<BudgetProgress?, BudgetMonth>
    totalBudgetProgressForMonthProvider =
    Provider.family<BudgetProgress?, BudgetMonth>((Ref ref, BudgetMonth m) {
  Budget? total;
  for (final Budget b in ref.watch(budgetListProvider)) {
    if (b.year == m.year &&
        b.month == m.month &&
        b.categoryId == kTotalBudgetCategoryId) {
      total = b;
      break;
    }
  }
  if (total == null) return null;
  double spent = 0;
  for (final Expense e in ref.watch(expenseListProvider)) {
    if (e.amount >= 0) continue;
    if (!m.contains(e.date)) continue;
    spent += -e.amount;
  }
  return BudgetProgress(budget: total, spent: spent);
});

/// Budgets for the month currently picked on the budget screen.
final Provider<List<BudgetProgress>> budgetProgressProvider =
    Provider<List<BudgetProgress>>((Ref ref) => ref.watch(
        budgetProgressForMonthProvider(
            ref.watch(selectedBudgetMonthProvider))));

/// Total-month-budget for the month currently picked on the budget screen.
final Provider<BudgetProgress?> totalBudgetProgressProvider =
    Provider<BudgetProgress?>((Ref ref) => ref.watch(
        totalBudgetProgressForMonthProvider(
            ref.watch(selectedBudgetMonthProvider))));

/// Aggregate totals for the month — used for the screen header card.
class BudgetSummary {
  const BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.overCount,
  });
  final double totalBudget;
  final double totalSpent;
  final int overCount;

  double get remaining => totalBudget - totalSpent;
  double get ratio => totalBudget <= 0 ? 0 : totalSpent / totalBudget;
}

final Provider<BudgetSummary> budgetSummaryProvider = Provider<BudgetSummary>(
  (Ref ref) {
    final List<BudgetProgress> rows = ref.watch(budgetProgressProvider);
    double total = 0;
    double spent = 0;
    int over = 0;
    for (final BudgetProgress p in rows) {
      total += p.budget.amount;
      spent += p.spent;
      if (p.isOver) over += 1;
    }
    return BudgetSummary(
      totalBudget: total,
      totalSpent: spent,
      overCount: over,
    );
  },
);
