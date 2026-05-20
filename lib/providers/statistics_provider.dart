import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'expense_provider.dart';

class MonthlyTotals {
  const MonthlyTotals({required this.income, required this.expense});
  final double income;
  final double expense;
  double get balance => income - expense;
}

final Provider<MonthlyTotals> currentMonthTotalsProvider =
    Provider<MonthlyTotals>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateTime now = DateTime.now();
  double income = 0;
  double expense = 0;
  for (final Expense e in all) {
    if (e.date.year != now.year || e.date.month != now.month) continue;
    if (e.amount >= 0) {
      income += e.amount;
    } else {
      expense += -e.amount;
    }
  }
  return MonthlyTotals(income: income, expense: expense);
});

final Provider<Map<String, double>> currentMonthByCategoryProvider =
    Provider<Map<String, double>>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final DateTime now = DateTime.now();
  final Map<String, double> byCategory = <String, double>{};
  for (final Expense e in all) {
    if (e.date.year != now.year || e.date.month != now.month) continue;
    if (e.amount >= 0) continue;
    byCategory.update(
      e.category,
      (double v) => v + -e.amount,
      ifAbsent: () => -e.amount,
    );
  }
  return byCategory;
});
