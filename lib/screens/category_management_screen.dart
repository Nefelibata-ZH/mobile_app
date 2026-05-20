import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/icon_catalog.dart';
import '../widgets/category_editor_sheet.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('类别管理'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/settings'),
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.trending_down), text: '支出'),
              Tab(icon: Icon(Icons.trending_up), text: '收入'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _CategoryList(isIncome: false),
            _CategoryList(isIncome: true),
          ],
        ),
        floatingActionButton: const _AddFab(),
      ),
    );
  }
}

class _AddFab extends ConsumerWidget {
  const _AddFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        final TabController tab = DefaultTabController.of(context);
        final bool incomeTab = tab.index == 1;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext _) =>
              CategoryEditorSheet(initial: null, defaultIncome: incomeTab),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('新建类别'),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.isIncome});
  final bool isIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Category> all = ref.watch(categoryListProvider);
    final List<Category> items =
        all.where((Category c) => c.isIncome == isIncome).toList();

    if (items.isEmpty) {
      return Center(
        child: Text(isIncome ? '还没有收入类别，点右下角新建' : '还没有支出类别，点右下角新建'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: items.length,
      separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 4),
      itemBuilder: (BuildContext context, int index) {
        final Category c = items[index];
        final Color color = Color(c.color);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(IconCatalog.resolve(c.icon), color: color),
            ),
            title: Text(c.name),
            subtitle: Text(isIncome ? '收入类别' : '支出类别'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext _) =>
                        CategoryEditorSheet(initial: c, defaultIncome: isIncome),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: () => _confirmDelete(context, ref, c),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final List<Expense> expenses = ref.read(expenseListProvider);
    final int usage =
        expenses.where((Expense e) => e.category == category.id).length;
    final List<Category> siblings = ref
        .read(categoryListProvider)
        .where((Category c) =>
            c.isIncome == category.isIncome && c.id != category.id)
        .toList();

    if (usage == 0) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('删除类别'),
          content: Text('确定删除「${category.name}」吗？该类别没有关联的记录。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (ok ?? false) {
        await ref.read(categoryListProvider.notifier).remove(category.id);
      }
      return;
    }

    if (siblings.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('无法删除'),
          content: Text(
            '「${category.name}」下还有 $usage 条记录，'
            '${category.isIncome ? '请先创建另一个收入类别' : '请先创建另一个支出类别'}'
            '再来删除。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final String? targetId = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _ReassignDialog(
        category: category,
        usage: usage,
        siblings: siblings,
      ),
    );
    if (targetId == null) return;
    await _reassignAndDelete(ref, category.id, targetId);
  }

  Future<void> _reassignAndDelete(
    WidgetRef ref,
    String fromId,
    String toId,
  ) async {
    final ExpenseListNotifier exNotifier =
        ref.read(expenseListProvider.notifier);
    final List<Expense> affected = ref
        .read(expenseListProvider)
        .where((Expense e) => e.category == fromId)
        .toList();
    for (final Expense e in affected) {
      await exNotifier.update(e.copyWith(category: toId));
    }
    await ref.read(categoryListProvider.notifier).remove(fromId);
  }
}

class _ReassignDialog extends StatefulWidget {
  const _ReassignDialog({
    required this.category,
    required this.usage,
    required this.siblings,
  });

  final Category category;
  final int usage;
  final List<Category> siblings;

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.siblings.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除并迁移记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '「${widget.category.name}」下还有 ${widget.usage} 条记录，'
            '将迁移到下方所选类别后删除：',
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: _selected,
            items: widget.siblings
                .map(
                  (Category c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          IconCatalog.resolve(c.icon),
                          color: Color(c.color),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? v) => setState(() => _selected = v),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('迁移并删除'),
        ),
      ],
    );
  }
}
