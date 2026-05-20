import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/icon_catalog.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('该类型暂无类别')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        final Category c = categories[index];
        final bool selected = c.id == selectedId;
        final Color color = Color(c.color);
        return Material(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelect(c),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: selected ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    IconCatalog.resolve(c.icon),
                    size: 22,
                    color: selected ? color : color.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? color : null,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
