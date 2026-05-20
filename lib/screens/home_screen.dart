import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/expense_provider.dart';
import '../providers/statistics_provider.dart';
import '../utils/formatters.dart';
import '../widgets/expense_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MonthlyTotals totals = ref.watch(currentMonthTotalsProvider);
    final List<dynamic> expenses = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/statistics'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '本月结余',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      Formatters.currency(totals.balance),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('收入 ${Formatters.currency(totals.income)}'),
                        ),
                        Expanded(
                          child: Text('支出 ${Formatters.currency(totals.expense)}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('还没有记录，点右下角加一笔'))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (BuildContext context, int index) =>
                        ExpenseCard(expense: expenses[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add'),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }
}
