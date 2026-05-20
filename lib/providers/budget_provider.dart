import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../services/database_service.dart';
import 'expense_provider.dart';

final StateNotifierProvider<BudgetListNotifier, List<Budget>>
    budgetListProvider =
    StateNotifierProvider<BudgetListNotifier, List<Budget>>(
  (Ref ref) => BudgetListNotifier(ref.watch(databaseServiceProvider)),
);

class BudgetListNotifier extends StateNotifier<List<Budget>> {
  BudgetListNotifier(this._db) : super(<Budget>[]) {
    _refresh();
  }

  final DatabaseService _db;

  void _refresh() {
    state = _db.budgetBox.values.toList();
  }

  Future<void> upsert(Budget budget) async {
    await _db.budgetBox.put(budget.id, budget);
    _refresh();
  }

  Future<void> remove(String id) async {
    await _db.budgetBox.delete(id);
    _refresh();
  }
}
