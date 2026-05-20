import 'package:hive_flutter/hive_flutter.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  late Box<Expense> _expenseBox;
  late Box<Category> _categoryBox;
  late Box<Budget> _budgetBox;

  Box<Expense> get expenseBox => _expenseBox;
  Box<Category> get categoryBox => _categoryBox;
  Box<Budget> get budgetBox => _budgetBox;

  Future<void> init() async {
    Hive
      ..registerAdapter(ExpenseAdapter())
      ..registerAdapter(CategoryAdapter())
      ..registerAdapter(BudgetAdapter());

    _expenseBox = await Hive.openBox<Expense>(AppConstants.expenseBoxName);
    _categoryBox = await Hive.openBox<Category>(AppConstants.categoryBoxName);
    _budgetBox = await Hive.openBox<Budget>(AppConstants.budgetBoxName);
  }

  Future<void> close() async {
    await Hive.close();
  }
}
