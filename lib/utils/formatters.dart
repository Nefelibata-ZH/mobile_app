import 'package:intl/intl.dart';

import 'constants.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: '¥',
    decimalDigits: 2,
  );

  static final DateFormat _date =
      DateFormat.yMMMd(AppConstants.defaultLocale);
  static final DateFormat _dateTime =
      DateFormat.yMMMd(AppConstants.defaultLocale).add_Hm();
  static final DateFormat _yearMonth =
      DateFormat.yM(AppConstants.defaultLocale);

  static String currency(double amount) => _currency.format(amount);
  static String signedCurrency(double amount) {
    final String sign = amount >= 0 ? '+' : '-';
    return '$sign${_currency.format(amount.abs())}';
  }

  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String yearMonth(DateTime value) => _yearMonth.format(value);
}
