import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/icon_catalog.dart';

class CategoryEditorSheet extends ConsumerStatefulWidget {
  const CategoryEditorSheet({
    super.key,
    required this.initial,
    required this.defaultIncome,
  });

  /// `null` means "create new". Otherwise we're editing an existing category.
  final Category? initial;

  /// The tab the user opened from — chosen as the default type for new entries.
  final bool defaultIncome;

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  final TextEditingController _name = TextEditingController();
  late bool _isIncome;
  late String _icon;
  late int _color;

  static const List<int> _palette = <int>[
    0xFFEF6C00,
    0xFF1976D2,
    0xFFD81B60,
    0xFF6D4C41,
    0xFFE53935,
    0xFF3949AB,
    0xFF00897B,
    0xFF039BE5,
    0xFF7B1FA2,
    0xFF607D8B,
    0xFF2E7D32,
    0xFFC2185B,
    0xFF00695C,
    0xFF5E35B1,
    0xFFFB8C00,
    0xFF455A64,
  ];

  @override
  void initState() {
    super.initState();
    final Category? c = widget.initial;
    _name.text = c?.name ?? '';
    _isIncome = c?.isIncome ?? widget.defaultIncome;
    _icon = c?.icon ?? _firstIconFor(_isIncome);
    _color = c?.color ?? _palette.first;
  }

  String _firstIconFor(bool income) {
    final List<MapEntry<String, IconData>> e =
        IconCatalog.entries(incomeOnly: income);
    return e.isEmpty ? 'category' : e.first.key;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return;
    final Category? existing = widget.initial;
    final Category next = existing == null
        ? Category(
            id: 'cat_${const Uuid().v4()}',
            name: name,
            icon: _icon,
            color: _color,
            type: _isIncome ? 'income' : 'expense',
          )
        : existing.copyWith(
            name: name,
            icon: _icon,
            color: _color,
            type: _isIncome ? 'income' : 'expense',
          );
    await ref.read(categoryListProvider.notifier).upsert(next);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initial != null;
    final Color accent = Color(_color);
    final List<MapEntry<String, IconData>> iconChoices =
        IconCatalog.entries(incomeOnly: _isIncome);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                isEdit ? '编辑类别' : '新建类别',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _PreviewTile(
                name: _name.text.trim().isEmpty ? '示例' : _name.text.trim(),
                icon: IconCatalog.resolve(_icon),
                color: accent,
                isIncome: _isIncome,
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('支出'),
                    icon: Icon(Icons.trending_down),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('收入'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: <bool>{_isIncome},
                onSelectionChanged: (Set<bool> v) => setState(() {
                  _isIncome = v.first;
                  // Switch to a valid icon for the new type if current isn't.
                  final List<String> keys = IconCatalog
                      .entries(incomeOnly: _isIncome)
                      .map((MapEntry<String, IconData> e) => e.key)
                      .toList();
                  if (!keys.contains(_icon)) {
                    _icon = keys.isEmpty ? 'category' : keys.first;
                  }
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '图标',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: iconChoices
                    .map(
                      (MapEntry<String, IconData> e) => _IconChip(
                        icon: e.value,
                        selected: e.key == _icon,
                        color: accent,
                        onTap: () => setState(() => _icon = e.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '颜色',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette
                    .map(
                      (int c) => _ColorDot(
                        color: Color(c),
                        selected: c == _color,
                        onTap: () => setState(() => _color = c),
                      ),
                    )
                    .toList(),
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
                      onPressed: _name.text.trim().isEmpty ? null : _save,
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
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  isIncome ? '收入类别' : '支出类别',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? color : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black87 : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
