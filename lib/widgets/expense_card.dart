import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/formatters.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({required this.expense, super.key});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color amountColor = expense.isIncome ? cs.primary : cs.error;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.surfaceContainerHighest,
        child: Text(
          expense.category.isEmpty ? '?' : expense.category.characters.first,
        ),
      ),
      title: Text(expense.category),
      subtitle: Text(
        '${Formatters.date(expense.date)} · ${expense.paymentMethod}'
        '${expense.note == null ? '' : ' · ${expense.note}'}',
      ),
      trailing: Text(
        Formatters.signedCurrency(expense.amount),
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
