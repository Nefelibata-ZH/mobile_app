import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../providers/ai_config_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../services/ai_extract_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/category_picker.dart';
import '../widgets/voice_capture_sheet.dart';

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
  String? _categoryId;
  String _paymentMethod = AppConstants.paymentMethods.first;
  DateTime _date = DateTime.now();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final bool valid = Validators.amount(_amountController.text) == null &&
        _categoryId != null;
    setState(() => _canSubmit = valid);
  }

  void _recomputeCanSubmit() {
    final bool valid = Validators.amount(_amountController.text) == null &&
        _categoryId != null;
    if (valid != _canSubmit) {
      setState(() => _canSubmit = valid);
    }
  }

  List<Category> _filteredCategories(List<Category> all) => all
      .where((Category c) => _isExpense ? !c.isIncome : c.isIncome)
      .toList();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _voiceCapture() async {
    final AiExtractedExpense? result =
        await showModalBottomSheet<AiExtractedExpense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const VoiceCaptureSheet(),
    );
    if (result == null || !mounted) return;
    _applyExtracted(result);
  }

  void _applyExtracted(AiExtractedExpense r) {
    // Treat each field as best-effort: only overwrite when the model
    // returned something usable, so the user's existing edits aren't
    // wiped by null/empty values.
    setState(() {
      if (r.kind != null) _isExpense = r.kind == 'expense';
      if (r.amount != null && r.amount! > 0) {
        _amountController.text = r.amount!.toStringAsFixed(
            r.amount!.truncateToDouble() == r.amount! ? 0 : 2);
      }
      if (r.categoryId != null) _categoryId = r.categoryId;
      if (r.paymentMethod != null) _paymentMethod = r.paymentMethod!;
      if (r.date != null) _date = r.date!;
      // Note: prefer the model's polished note, but if extraction failed
      // and only the raw transcript came back, keep that so the user's
      // words survive a round-trip.
      final String? noteToUse = r.note ?? r.rawTranscript;
      if (noteToUse != null && noteToUse.trim().isNotEmpty) {
        _noteController.text = noteToUse.trim();
      }
    });
    _recomputeCanSubmit();
    final List<String> filled = <String>[
      if (r.kind != null) (r.kind == 'expense' ? '支出/收入' : '支出/收入'),
      if (r.amount != null) '金额',
      if (r.categoryId != null) '类别',
      if (r.paymentMethod != null) '支付方式',
      if (r.date != null) '日期',
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          filled.isEmpty
              ? '已填入备注，请手动补全其余字段'
              : '已填入：${filled.join('、')}，请确认无误后保存',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) return;
    final List<Category> all = ref.read(categoryListProvider);
    final Category category =
        all.firstWhere((Category c) => c.id == _categoryId);
    final double raw = double.parse(_amountController.text.trim());
    final double signed = _isExpense ? -raw.abs() : raw.abs();
    await ref.read(expenseListProvider.notifier).add(
          amount: signed,
          category: category.id,
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
    final Color accent =
        _isExpense ? AppColors.expense : AppColors.income;
    final List<Category> categories =
        _filteredCategories(ref.watch(categoryListProvider));

    if (_categoryId != null &&
        !categories.any((Category c) => c.id == _categoryId)) {
      _categoryId = null;
    }

    final double? parsed = double.tryParse(_amountController.text.trim());
    final String preview = (parsed == null || parsed == 0)
        ? '—'
        : '${_isExpense ? '-' : '+'}¥${Formatters.plainAmount(parsed.abs())}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        actions: <Widget>[
          if (ref.watch(aiConfigProvider).isUsable)
            IconButton(
              icon: const Icon(Icons.mic_none),
              tooltip: '语音记账',
              onPressed: _voiceCapture,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: _recomputeCanSubmit,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  label: Text('支出'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('收入'),
                  icon: Icon(Icons.trending_up),
                ),
              ],
              selected: <bool>{_isExpense},
              onSelectionChanged: (Set<bool> v) => setState(() {
                _isExpense = v.first;
                _categoryId = null;
              }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected)
                          ? accent.withValues(alpha: 0.18)
                          : null,
                ),
                foregroundColor:
                    WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) =>
                      states.contains(WidgetState.selected) ? accent : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                _SingleDotFormatter(),
              ],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
              decoration: InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                helperText: preview,
                helperStyle: TextStyle(color: accent),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
              validator: Validators.amount,
            ),
            const SizedBox(height: 20),
            Text('类别', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            CategoryPicker(
              categories: categories,
              selectedId: _categoryId,
              onSelect: (Category c) {
                setState(() => _categoryId = c.id);
                _recomputeCanSubmit();
              },
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
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('日期'),
              subtitle: Text(Formatters.date(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('修改'),
              ),
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('取消'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('保存'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SingleDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if ('.'.allMatches(newValue.text).length > 1) return oldValue;
    final int dot = newValue.text.indexOf('.');
    if (dot >= 0 && newValue.text.length - dot - 1 > 2) return oldValue;
    return newValue;
  }
}
