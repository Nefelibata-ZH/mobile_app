import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'expense_provider.dart';

class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) =>
      !d.isBefore(start) && d.isBefore(end);
}

enum RangePreset { month, year, custom }

class RangeSelection {
  const RangeSelection({required this.preset, this.custom});
  final RangePreset preset;
  final DateRange? custom;

  DateRange resolve() {
    final DateTime now = DateTime.now();
    switch (preset) {
      case RangePreset.month:
        return DateRange(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
      case RangePreset.year:
        return DateRange(DateTime(now.year), DateTime(now.year + 1));
      case RangePreset.custom:
        return custom ??
            DateRange(
              DateTime(now.year, now.month),
              DateTime(now.year, now.month + 1),
            );
    }
  }
}

final StateProvider<RangeSelection> rangeSelectionProvider =
    StateProvider<RangeSelection>(
  (Ref ref) => const RangeSelection(preset: RangePreset.month),
);

/// Whether statistics screen is showing expense (true) or income (false).
/// Shared between the pie tab toggle and the insights bar so they stay in sync.
final StateProvider<bool> statisticsExpenseModeProvider =
    StateProvider<bool>((Ref ref) => true);

class Totals {
  const Totals({required this.income, required this.expense});
  final double income;
  final double expense;
  double get balance => income - expense;
}

Totals _totalsIn(List<Expense> all, DateRange r) {
  double income = 0;
  double expense = 0;
  for (final Expense e in all) {
    if (!r.contains(e.date)) continue;
    if (e.amount >= 0) {
      income += e.amount;
    } else {
      expense += -e.amount;
    }
  }
  return Totals(income: income, expense: expense);
}

/// Always the **current month**, used by the home summary card.
final Provider<Totals> currentMonthTotalsProvider = Provider<Totals>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateTime now = DateTime.now();
  return _totalsIn(
    all,
    DateRange(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ),
  );
});

/// Drives the Statistics screen — depends on selected range.
final Provider<Totals> rangeTotalsProvider = Provider<Totals>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateRange r = ref.watch(rangeSelectionProvider).resolve();
  return _totalsIn(all, r);
});

final Provider<Map<String, double>> rangeExpenseByCategoryProvider =
    Provider<Map<String, double>>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateRange r = ref.watch(rangeSelectionProvider).resolve();
  final Map<String, double> by = <String, double>{};
  for (final Expense e in all) {
    if (!r.contains(e.date)) continue;
    if (e.amount >= 0) continue;
    by.update(
      e.category,
      (double v) => v + -e.amount,
      ifAbsent: () => -e.amount,
    );
  }
  return by;
});

final Provider<Map<String, double>> rangeIncomeByCategoryProvider =
    Provider<Map<String, double>>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateRange r = ref.watch(rangeSelectionProvider).resolve();
  final Map<String, double> by = <String, double>{};
  for (final Expense e in all) {
    if (!r.contains(e.date)) continue;
    if (e.amount <= 0) continue;
    by.update(
      e.category,
      (double v) => v + e.amount,
      ifAbsent: () => e.amount,
    );
  }
  return by;
});

class TrendPoint {
  const TrendPoint({required this.date, required this.income, required this.expense});
  final DateTime date;
  final double income;
  final double expense;
}

/// Daily trend within the selected range.
final Provider<List<TrendPoint>> rangeTrendProvider =
    Provider<List<TrendPoint>>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateRange r = ref.watch(rangeSelectionProvider).resolve();
  final Map<DateTime, List<double>> bucket = <DateTime, List<double>>{};
  for (final Expense e in all) {
    if (!r.contains(e.date)) continue;
    final DateTime d = DateTime(e.date.year, e.date.month, e.date.day);
    final List<double> v = bucket.putIfAbsent(d, () => <double>[0, 0]);
    if (e.amount >= 0) {
      v[0] += e.amount;
    } else {
      v[1] += -e.amount;
    }
  }
  final List<DateTime> keys = bucket.keys.toList()..sort();
  return keys
      .map(
        (DateTime d) => TrendPoint(
          date: d,
          income: bucket[d]![0],
          expense: bucket[d]![1],
        ),
      )
      .toList();
});

class RangeInsights {
  const RangeInsights({
    required this.dailyExpenseAvg,
    required this.maxExpense,
    required this.topCategoryId,
  });
  final double dailyExpenseAvg;
  final double maxExpense;
  final String? topCategoryId;
}

final Provider<RangeInsights> rangeInsightsProvider = Provider<RangeInsights>(
  (Ref ref) {
    final bool expenseMode = ref.watch(statisticsExpenseModeProvider);
    final List<Expense> all = ref.watch(expenseListProvider);
    final DateRange r = ref.watch(rangeSelectionProvider).resolve();
    double total = 0;
    double maxOne = 0;
    final Map<String, int> counts = <String, int>{};
    for (final Expense e in all) {
      if (!r.contains(e.date)) continue;
      // expense entries have negative amount; income entries have positive.
      final bool isExpense = e.amount < 0;
      if (expenseMode != isExpense) continue;
      final double v = expenseMode ? -e.amount : e.amount;
      total += v;
      if (v > maxOne) maxOne = v;
      counts.update(e.category, (int c) => c + 1, ifAbsent: () => 1);
    }
    final int days = r.end.difference(r.start).inDays.clamp(1, 1000000);
    String? top;
    int topCount = 0;
    counts.forEach((String k, int v) {
      if (v > topCount) {
        top = k;
        topCount = v;
      }
    });
    return RangeInsights(
      dailyExpenseAvg: total / days,
      maxExpense: maxOne,
      topCategoryId: top,
    );
  },
);
