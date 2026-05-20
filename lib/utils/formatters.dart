import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: '¥',
    decimalDigits: 2,
  );

  static final NumberFormat _plain = NumberFormat('#,##0.00', 'en_US');

  static String currency(double amount) => _currency.format(amount);

  static String signedCurrency(double amount) {
    final String sign = amount >= 0 ? '+' : '-';
    return '$sign${_currency.format(amount.abs())}';
  }

  /// Plain "1,234.56" preview without currency symbol.
  static String plainAmount(double amount) => _plain.format(amount);

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String date(DateTime v) =>
      '${v.year}-${_two(v.month)}-${_two(v.day)}';

  static String dateTime(DateTime v) =>
      '${date(v)} ${_two(v.hour)}:${_two(v.minute)}';

  static String yearMonth(DateTime v) => '${v.year}-${_two(v.month)}';

  static String monthDay(DateTime v) => '${_two(v.month)}-${_two(v.day)}';
}

/// Semantic accent colors per the spec: 收入蓝 / 支出红 / 结余绿.
class AppColors {
  AppColors._();
  static const Color income = Color(0xFF1E88E5);
  static const Color expense = Color(0xFFE53935);
  static const Color balance = Color(0xFF2E7D32);
}
