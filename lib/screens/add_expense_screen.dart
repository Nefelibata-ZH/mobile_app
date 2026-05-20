import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isExpense = true;
  String _category = '餐饮';
  String _paymentMethod = AppConstants.paymentMethods.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final double raw = double.parse(_amountController.text.trim());
    final double signed = _isExpense ? -raw.abs() : raw.abs();
    await ref.read(expenseListProvider.notifier).add(
          amount: signed,
          category: _category,
          date: _date,
          paymentMethod: _paymentMethod,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: true, label: Text('支出')),
                ButtonSegment<bool>(value: false, label: Text('收入')),
              ],
              selected: <bool>{_isExpense},
              onSelectionChanged: (Set<bool> v) =>
                  setState(() => _isExpense = v.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              validator: Validators.amount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '类别',
                border: OutlineInputBorder(),
              ),
              onChanged: (String v) => _category = v,
              validator: (String? v) =>
                  Validators.required(v, field: '类别'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: '支付方式',
                border: OutlineInputBorder(),
              ),
              items: AppConstants.paymentMethods
                  .map(
                    (String m) => DropdownMenuItem<String>(
                      value: m,
                      child: Text(m),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) =>
                  setState(() => _paymentMethod = v ?? _paymentMethod),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
