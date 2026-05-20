import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/database_service.dart';
import 'expense_provider.dart';

final StateNotifierProvider<CategoryListNotifier, List<Category>>
    categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<Category>>(
  (Ref ref) => CategoryListNotifier(ref.watch(databaseServiceProvider)),
);

final Provider<Map<String, Category>> categoryByIdProvider =
    Provider<Map<String, Category>>((Ref ref) {
  final List<Category> all = ref.watch(categoryListProvider);
  return <String, Category>{for (final Category c in all) c.id: c};
});

class CategoryListNotifier extends StateNotifier<List<Category>> {
  CategoryListNotifier(this._db) : super(<Category>[]) {
    _refresh();
  }

  final DatabaseService _db;

  void _refresh() {
    state = _db.categoryBox.values.toList();
  }

  Future<void> upsert(Category category) async {
    await _db.categoryBox.put(category.id, category);
    _refresh();
  }

  Future<void> remove(String id) async {
    await _db.categoryBox.delete(id);
    _refresh();
  }
}
