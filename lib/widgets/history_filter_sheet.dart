import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/expense_filter_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/icon_catalog.dart';

class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({super.key});

  @override
  ConsumerState<HistoryFilterSheet> createState() =>
      _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  late ExpenseFilter _draft;
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(expenseFilterProvider);
    if (_draft.minAmount != null) _min.text = _draft.minAmount!.toStringAsFixed(0);
    if (_draft.maxAmount != null) _max.text = _draft.maxAmount!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _toggle<T>(Set<T> set, T value, void Function(Set<T>) apply) {
    final Set<T> next = <T>{...set};
    if (!next.add(value)) next.remove(value);
    apply(next);
  }

  Future<void> _pickRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _draft.start != null && _draft.end != null
          ? DateTimeRange(start: _draft.start!, end: _draft.end!.subtract(const Duration(days: 1)))
          : null,
    );
    if (picked == null) return;
    setState(() => _draft = _draft.copyWith(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day)
              .add(const Duration(days: 1)),
        ));
  }

  void _apply() {
    final double? mn = _min.text.trim().isEmpty
        ? null
        : double.tryParse(_min.text.trim());
    final double? mx = _max.text.trim().isEmpty
        ? null
        : double.tryParse(_max.text.trim());
    final ExpenseFilter next = _draft.copyWith(
      minAmount: mn,
      maxAmount: mx,
      clearMin: mn == null,
      clearMax: mx == null,
    );
    ref.read(expenseFilterProvider.notifier).state = next;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _draft = const ExpenseFilter();
      _min.clear();
      _max.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> categories = ref.watch(categoryListProvider);

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
              Row(
                children: <Widget>[
                  Text('筛选',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: _draft.isActive ? _reset : null,
                    child: const Text('重置'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SectionLabel(label: '类型'),
              const SizedBox(height: 8),
              SegmentedButton<ExpenseKindFilter>(
                segments: const <ButtonSegment<ExpenseKindFilter>>[
                  ButtonSegment<ExpenseKindFilter>(
                    value: ExpenseKindFilter.all,
                    label: Text('全部'),
                  ),
                  ButtonSegment<ExpenseKindFilter>(
                    value: ExpenseKindFilter.expense,
                    label: Text('支出'),
                    icon: Icon(Icons.trending_down),
                  ),
                  ButtonSegment<ExpenseKindFilter>(
                    value: ExpenseKindFilter.income,
                    label: Text('收入'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: <ExpenseKindFilter>{_draft.kind},
                onSelectionChanged: (Set<ExpenseKindFilter> v) =>
                    setState(() => _draft = _draft.copyWith(kind: v.first)),
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: '日期'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickRange,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.event),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _draft.start == null || _draft.end == null
                              ? '选择日期范围'
                              : '${Formatters.date(_draft.start!)} ~ ${Formatters.date(_draft.end!.subtract(const Duration(days: 1)))}',
                        ),
                      ),
                      if (_draft.start != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _draft = _draft
                              .copyWith(clearStart: true, clearEnd: true)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: '金额范围'),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: '最小',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('—'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: '最大',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: '类别'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.map((Category c) {
                  final bool sel = _draft.categoryIds.contains(c.id);
                  return FilterChip(
                    selected: sel,
                    avatar: Icon(
                      IconCatalog.resolve(c.icon),
                      size: 16,
                      color: sel ? Color(c.color) : null,
                    ),
                    label: Text(c.name),
                    onSelected: (_) => _toggle(_draft.categoryIds, c.id,
                        (Set<String> next) => setState(() =>
                            _draft = _draft.copyWith(categoryIds: next))),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: '支付方式'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppConstants.paymentMethods.map((String pm) {
                  final bool sel = _draft.paymentMethods.contains(pm);
                  return FilterChip(
                    selected: sel,
                    label: Text(pm),
                    onSelected: (_) => _toggle(_draft.paymentMethods, pm,
                        (Set<String> next) => setState(() =>
                            _draft = _draft.copyWith(paymentMethods: next))),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
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
                      onPressed: _apply,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('应用筛选'),
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
