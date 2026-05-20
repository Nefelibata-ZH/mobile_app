import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Totals totals = ref.watch(currentMonthTotalsProvider);
    final List<Expense> expenses = ref.watch(expenseListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('记账本'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: '统计',
              onPressed: () => context.go('/statistics'),
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: '历史',
              onPressed: () => context.go('/history'),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: '设置',
              onPressed: () => context.go('/settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.list_alt), text: '最近交易'),
              Tab(icon: Icon(Icons.pie_chart), text: '本月概览'),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            SummaryCard(
              title: '本月概览',
              income: totals.income,
              expense: totals.expense,
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _RecentTransactions(expenses: expenses),
                  const _MonthOverviewTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/add'),
          icon: const Icon(Icons.add),
          label: const Text('记一笔'),
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text('还没有记录，点右下角加一笔'));
    }
    final List<Expense> recent =
        expenses.length > 30 ? expenses.sublist(0, 30) : expenses;
    return ListView.builder(
      itemCount: recent.length,
      itemBuilder: (BuildContext context, int index) =>
          ExpenseCard(expense: recent[index]),
    );
  }
}

class _MonthOverviewTab extends ConsumerWidget {
  const _MonthOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, double> byCategory =
        ref.watch(rangeExpenseByCategoryProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '本月支出占比',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          CategoryPieChart(
            byCategory: byCategory,
            categoryById: ref.watch(categoryByIdProvider),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/statistics'),
              icon: const Icon(Icons.insights),
              label: const Text('查看完整统计'),
            ),
          ),
        ],
      ),
    );
  }
}
