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
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        final Category c = categories[index];
        final bool selected = c.id == selectedId;
        final Color color = Color(c.color);
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(c),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? color
                    : color.withValues(alpha: 0.18),
                child: Icon(
                  IconCatalog.resolve(c.icon),
                  color: selected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
