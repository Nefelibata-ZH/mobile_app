import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'expense_provider.dart';

/// User-driven filter applied on top of the full expense list.
///
/// All fields are optional and combine with AND. Strings are matched
/// case-insensitively against the note, category id, and payment method
/// so the search bar in history covers the obvious user intents without
/// per-field configuration.
class ExpenseFilter {
  const ExpenseFilter({
    this.query = '',
    this.categoryIds = const <String>{},
    this.paymentMethods = const <String>{},
    this.start,
    this.end,
    this.minAmount,
    this.maxAmount,
    this.kind = ExpenseKindFilter.all,
  });

  final String query;
  final Set<String> categoryIds;
  final Set<String> paymentMethods;
  final DateTime? start;
  final DateTime? end;
  final double? minAmount;
  final double? maxAmount;
  final ExpenseKindFilter kind;

  bool get isActive =>
      query.isNotEmpty ||
      categoryIds.isNotEmpty ||
      paymentMethods.isNotEmpty ||
      start != null ||
      end != null ||
      minAmount != null ||
      maxAmount != null ||
      kind != ExpenseKindFilter.all;

  /// Number of distinct dimensions in use — drives the badge on the
  /// filter button so users can tell at a glance what's narrowed.
  int get activeCount {
    int n = 0;
    if (query.isNotEmpty) n++;
    if (categoryIds.isNotEmpty) n++;
    if (paymentMethods.isNotEmpty) n++;
    if (start != null || end != null) n++;
    if (minAmount != null || maxAmount != null) n++;
    if (kind != ExpenseKindFilter.all) n++;
    return n;
  }

  ExpenseFilter copyWith({
    String? query,
    Set<String>? categoryIds,
    Set<String>? paymentMethods,
    DateTime? start,
    DateTime? end,
    double? minAmount,
    double? maxAmount,
    ExpenseKindFilter? kind,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearMin = false,
    bool clearMax = false,
  }) {
    return ExpenseFilter(
      query: query ?? this.query,
      categoryIds: categoryIds ?? this.categoryIds,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
      kind: kind ?? this.kind,
    );
  }

  bool matches(Expense e) {
    if (kind == ExpenseKindFilter.expense && e.amount >= 0) return false;
    if (kind == ExpenseKindFilter.income && e.amount < 0) return false;

    if (categoryIds.isNotEmpty && !categoryIds.contains(e.category)) {
      return false;
    }
    if (paymentMethods.isNotEmpty &&
        !paymentMethods.contains(e.paymentMethod)) {
      return false;
    }
    if (start != null && e.date.isBefore(start!)) return false;
    if (end != null && !e.date.isBefore(end!)) return false;

    final double abs = e.amount.abs();
    if (minAmount != null && abs < minAmount!) return false;
    if (maxAmount != null && abs > maxAmount!) return false;

    if (query.isNotEmpty) {
      final String q = query.toLowerCase();
      final bool hit = (e.note ?? '').toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.paymentMethod.toLowerCase().contains(q);
      if (!hit) return false;
    }
    return true;
  }
}

enum ExpenseKindFilter { all, expense, income }

final StateProvider<ExpenseFilter> expenseFilterProvider =
    StateProvider<ExpenseFilter>((Ref ref) => const ExpenseFilter());

final Provider<List<Expense>> filteredExpensesProvider =
    Provider<List<Expense>>((Ref ref) {
  final List<Expense> all = ref.watch(expenseListProvider);
  final ExpenseFilter f = ref.watch(expenseFilterProvider);
  if (!f.isActive) return all;
  return all.where(f.matches).toList();
});
