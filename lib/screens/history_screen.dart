import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_filter_provider.dart';
import '../services/csv_export_result.dart';
import '../services/csv_export_service.dart';
import '../utils/formatters.dart';
import '../widgets/expense_card.dart';
import '../widgets/history_filter_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(expenseFilterProvider).query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    final ExpenseFilter f = ref.read(expenseFilterProvider);
    ref.read(expenseFilterProvider.notifier).state =
        f.copyWith(query: v.trim());
  }

  Future<void> _export() async {
    final List<Expense> rows = ref.read(filteredExpensesProvider);
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可导出的记录')),
      );
      return;
    }
    try {
      final CsvExportResult result = await const CsvExportService().export(
        expenses: rows,
        categoryById: ref.read(categoryByIdProvider),
      );
      if (!mounted) return;
      final String message = result.savedToDisk
          ? '已导出 ${rows.length} 条到 ${result.location}'
          : '已下载 ${rows.length} 条到浏览器：${result.location}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Expense> filtered = ref.watch(filteredExpensesProvider);
    final ExpenseFilter filter = ref.watch(expenseFilterProvider);

    final double totalIncome = filtered
        .where((Expense e) => e.amount >= 0)
        .fold<double>(0, (double a, Expense e) => a + e.amount);
    final double totalExpense = filtered
        .where((Expense e) => e.amount < 0)
        .fold<double>(0, (double a, Expense e) => a + -e.amount);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: '搜索备注 / 类别 / 支付方式',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const Text('历史记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_searching) {
              setState(() {
                _searching = false;
                _search.clear();
                _onSearchChanged('');
              });
            } else {
              context.go('/');
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? '关闭搜索' : '搜索',
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _search.clear();
                  _onSearchChanged('');
                }
              });
            },
          ),
          Stack(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: '筛选',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const HistoryFilterSheet(),
                ),
              ),
              if (filter.activeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${filter.activeCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出 CSV',
            onPressed: _export,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (filter.isActive)
            _ResultBanner(
              count: filtered.length,
              income: totalIncome,
              expense: totalExpense,
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      filter.isActive ? '没有匹配的记录' : '暂无记录',
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) =>
                        ExpenseCard(expense: filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.count,
    required this.income,
    required this.expense,
  });

  final int count;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: <Widget>[
          Text('$count 条结果',
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          if (income > 0) ...<Widget>[
            const Icon(Icons.trending_up,
                size: 14, color: AppColors.income),
            const SizedBox(width: 2),
            Text(
              Formatters.currency(income),
              style: const TextStyle(
                color: AppColors.income,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (expense > 0) ...<Widget>[
            const Icon(Icons.trending_down,
                size: 14, color: AppColors.expense),
            const SizedBox(width: 2),
            Text(
              Formatters.currency(expense),
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
