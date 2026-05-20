import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/expense_service.dart';

final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) => DatabaseService.instance);

final Provider<ExpenseService> expenseServiceProvider =
    Provider<ExpenseService>(
  (Ref ref) => ExpenseService(ref.watch(databaseServiceProvider)),
);

final StateNotifierProvider<ExpenseListNotifier, List<Expense>>
    expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, List<Expense>>(
  (Ref ref) => ExpenseListNotifier(ref.watch(expenseServiceProvider)),
);

class ExpenseListNotifier extends StateNotifier<List<Expense>> {
  ExpenseListNotifier(this._service) : super(<Expense>[]) {
    _refresh();
  }

  final ExpenseService _service;

  void _refresh() {
    state = _service.all();
  }

  Future<void> add({
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String? note,
  }) async {
    await _service.add(
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      note: note,
    );
    _refresh();
  }

  Future<void> update(Expense expense) async {
    await _service.update(expense);
    _refresh();
  }

  Future<void> remove(String id) async {
    await _service.remove(id);
    _refresh();
  }
}
