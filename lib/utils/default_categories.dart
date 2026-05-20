import '../models/category.dart';

/// Default categories injected on first launch.
///
/// Stored ids are stable so user-entered expenses survive seeded reruns.
class DefaultCategories {
  DefaultCategories._();

  static List<Category> all() => <Category>[
        // Expense
        Category(
          id: 'cat_food',
          name: '餐饮',
          icon: 'restaurant',
          color: 0xFFEF6C00,
          type: 'expense',
        ),
        Category(
          id: 'cat_transport',
          name: '交通',
          icon: 'directions_car',
          color: 0xFF1976D2,
          type: 'expense',
        ),
        Category(
          id: 'cat_shopping',
          name: '购物',
          icon: 'shopping_bag',
          color: 0xFFD81B60,
          type: 'expense',
        ),
        Category(
          id: 'cat_housing',
          name: '居家',
          icon: 'home',
          color: 0xFF6D4C41,
          type: 'expense',
        ),
        Category(
          id: 'cat_medical',
          name: '医疗',
          icon: 'medical_services',
          color: 0xFFE53935,
          type: 'expense',
        ),
        Category(
          id: 'cat_education',
          name: '教育',
          icon: 'school',
          color: 0xFF3949AB,
          type: 'expense',
        ),
        Category(
          id: 'cat_entertainment',
          name: '娱乐',
          icon: 'sports_esports',
          color: 0xFF00897B,
          type: 'expense',
        ),
        Category(
          id: 'cat_travel',
          name: '旅行',
          icon: 'flight',
          color: 0xFF039BE5,
          type: 'expense',
        ),
        Category(
          id: 'cat_phone',
          name: '通讯',
          icon: 'phone_iphone',
          color: 0xFF7B1FA2,
          type: 'expense',
        ),
        Category(
          id: 'cat_other_expense',
          name: '其他',
          icon: 'receipt_long',
          color: 0xFF607D8B,
          type: 'expense',
        ),
        // Income
        Category(
          id: 'cat_salary',
          name: '工资',
          icon: 'work',
          color: 0xFF2E7D32,
          type: 'income',
        ),
        Category(
          id: 'cat_bonus',
          name: '奖金',
          icon: 'redeem',
          color: 0xFFC2185B,
          type: 'income',
        ),
        Category(
          id: 'cat_invest',
          name: '理财',
          icon: 'trending_up',
          color: 0xFF00695C,
          type: 'income',
        ),
        Category(
          id: 'cat_other_income',
          name: '其他收入',
          icon: 'savings',
          color: 0xFF5E35B1,
          type: 'income',
        ),
      ];
}
