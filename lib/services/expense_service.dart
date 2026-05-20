import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import 'database_service.dart';

class ExpenseService {
  ExpenseService(this._db);

  final DatabaseService _db;
  final Uuid _uuid = const Uuid();

  List<Expense> all() => _db.expenseBox.values.toList()
    ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

  Future<Expense> add({
    required double amount,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String? note,
  }) async {
    final Expense expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      note: note,
    );
    await _db.expenseBox.put(expense.id, expense);
    return expense;
  }

  Future<void> update(Expense expense) async {
    await _db.expenseBox.put(expense.id, expense);
  }

  Future<void> remove(String id) async {
    await _db.expenseBox.delete(id);
  }
}
