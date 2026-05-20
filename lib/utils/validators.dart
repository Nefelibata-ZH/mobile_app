class Validators {
  Validators._();

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入金额';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '金额格式不正确';
    }
    if (parsed == 0) {
      return '金额不能为 0';
    }
    return null;
  }

  static String? required(String? value, {String field = '该项'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field不能为空';
    }
    return null;
  }
}
