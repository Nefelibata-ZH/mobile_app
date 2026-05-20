import 'package:flutter/material.dart';

/// Hive can't serialize [IconData] directly (tree-shake breaks const lookup),
/// so categories store an icon **name** and we resolve to [IconData] here.
class IconCatalog {
  IconCatalog._();

  static const Map<String, IconData> _icons = <String, IconData>{
    // Expense
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'home': Icons.home,
    'medical_services': Icons.medical_services,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
    'flight': Icons.flight,
    'local_cafe': Icons.local_cafe,
    'pets': Icons.pets,
    'receipt_long': Icons.receipt_long,
    'phone_iphone': Icons.phone_iphone,
    // Income
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'redeem': Icons.redeem,
    'savings': Icons.savings,
    // Fallback
    'category': Icons.category,
  };

  static IconData resolve(String name) =>
      _icons[name] ?? Icons.category;

  static List<MapEntry<String, IconData>> entries(
      {required bool incomeOnly}) {
    const Set<String> incomeIcons = <String>{
      'work',
      'trending_up',
      'redeem',
      'savings',
    };
    return _icons.entries.where((MapEntry<String, IconData> e) {
      final bool isIncome = incomeIcons.contains(e.key);
      return incomeOnly ? isIncome : !isIncome;
    }).toList();
  }
}
