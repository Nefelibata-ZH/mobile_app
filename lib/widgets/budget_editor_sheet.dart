import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../providers/budget_progress_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';
import '../utils/validators.dart';

class BudgetEditorSheet extends ConsumerStatefulWidget {
  const BudgetEditorSheet({
    super.key,
    required this.initial,
    required this.month,
  });

  final Budget? initial;
  final BudgetMonth month;

  @override
  ConsumerState<BudgetEditorSheet> createState() =>
      _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<BudgetEditorSheet> {
  final TextEditingController _amount = TextEditingController();
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final Budget? b = widget.initial;
    if (b != null) {
      _categoryId = b.categoryId;
      _amount.text = b.amount.toStringAsFixed(b.amount.truncateToDouble() ==
              b.amount
          ? 0
          : 2);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _idFor(int year, int month, String categoryId) =>
      'bgt_${year}_${month}_$categoryId';

  Future<void> _save() async {
    final String? err = Validators.amount(_amount.text);
    if (err != null || _categoryId == null) return;
    final double amt = double.parse(_amount.text.trim()).abs();
    final Budget? existing = widget.initial;
    final Budget next = existing == null
        ? Budget(
            id: _idFor(widget.month.year, widget.month.month, _categoryId!),
            categoryId: _categoryId!,
            amount: amt,
            month: widget.month.month,
            year: widget.month.year,
          )
        : existing.copyWith(amount: amt);
    await ref.read(budgetListProvider.notifier).upsert(next);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initial != null;
    final Map<String, Category> map = ref.watch(categoryByIdProvider);
    // Only expense categories get budgets — income doesn't have a "limit".
    final List<Category> all = ref
        .watch(categoryListProvider)
        .where((Category c) => !c.isIncome)
        .toList();

    // When creating, hide categories that already have a budget this month.
    final Set<String> taken = ref
        .read(budgetListProvider)
        .where((Budget b) =>
            b.year == widget.month.year && b.month == widget.month.month)
        .map((Budget b) => b.categoryId)
        .toSet();
    final List<Category> selectable = isEdit
        ? all
        : all.where((Category c) => !taken.contains(c.id)).toList();

    final Category? selected =
        _categoryId == null ? null : map[_categoryId];
    final Color accent =
        selected == null ? AppColors.expense : Color(selected.color);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? '编辑预算' : '新建预算',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.month.label} 月度预算',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isEdit && selected != null)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.18),
                    child: Icon(
                      IconCatalog.resolve(selected.icon),
                      color: accent,
                    ),
                  ),
                  title: Text(selected.name),
                  subtitle: const Text('类别（编辑模式不可修改）'),
                )
              else
                _CategoryGrid(
                  categories: selectable,
                  selectedId: _categoryId,
                  onSelect: (String id) =>
                      setState(() => _categoryId = id),
                ),
              if (!isEdit && selectable.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '本月所有支出类别都已有预算',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
                decoration: InputDecoration(
                  labelText: '预算金额',
                  prefixText: '¥ ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('取消'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canSave() ? _save : null,
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(isEdit ? '保存' : '创建'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave() =>
      _categoryId != null &&
      Validators.amount(_amount.text) == null &&
      double.tryParse(_amount.text.trim()) != 0;
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((Category c) {
        final bool sel = c.id == selectedId;
        final Color color = Color(c.color);
        return InkWell(
          onTap: () => onSelect(c.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? color.withValues(alpha: 0.18) : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? color
                    : Theme.of(context).colorScheme.outlineVariant,
                width: sel ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(IconCatalog.resolve(c.icon),
                    size: 16, color: sel ? color : null),
                const SizedBox(width: 6),
                Text(c.name,
                    style: TextStyle(
                      color: sel ? color : null,
                      fontWeight: sel ? FontWeight.w600 : null,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
