import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';

class ExpenseCard extends ConsumerWidget {
  const ExpenseCard({required this.expense, super.key});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Category? category =
        ref.watch(categoryByIdProvider)[expense.category];

    final Color amountColor =
        expense.isIncome ? AppColors.income : AppColors.expense;
    final Color categoryColor =
        category != null ? Color(category.color) : cs.outlineVariant;
    final IconData iconData = category != null
        ? IconCatalog.resolve(category.icon)
        : Icons.category;
    final String title = category?.name ?? '未分类';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: categoryColor.withValues(alpha: 0.18),
        child: Icon(iconData, color: categoryColor),
      ),
      title: Text(title),
      subtitle: Text(
        '${Formatters.date(expense.date)} · ${expense.paymentMethod}'
        '${expense.note == null ? '' : ' · ${expense.note}'}',
      ),
      trailing: Text(
        Formatters.signedCurrency(expense.amount),
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
      ),
      onLongPress: () => _confirmDelete(context, ref),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除该笔记录？'),
        content: Text(
          '${Formatters.date(expense.date)}  '
          '${Formatters.signedCurrency(expense.amount)}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(expenseListProvider.notifier).remove(expense.id);
    }
  }
}
