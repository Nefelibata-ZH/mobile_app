class AppConstants {
  AppConstants._();

  static const String expenseBoxName = 'expenses';
  static const String categoryBoxName = 'categories';
  static const String budgetBoxName = 'budgets';

  static const String defaultCurrency = 'CNY';
  static const String defaultLocale = 'zh_CN';

  static const List<String> paymentMethods = <String>[
    '现金',
    '信用卡',
    '借记卡',
    '微信',
    '支付宝',
    '其他',
  ];
}
