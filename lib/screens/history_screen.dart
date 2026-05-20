import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Expense> expenses = ref.watch(expenseListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('暂无记录'))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (BuildContext context, int index) =>
                  ExpenseCard(expense: expenses[index]),
            ),
    );
  }
}
