import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/utils/validators.dart';

void main() {
  group('Validators.amount', () {
    test('rejects empty', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount(null), isNotNull);
    });

    test('rejects non-number', () {
      expect(Validators.amount('abc'), isNotNull);
    });

    test('rejects zero', () {
      expect(Validators.amount('0'), isNotNull);
    });

    test('accepts valid amount', () {
      expect(Validators.amount('12.5'), isNull);
      expect(Validators.amount('-12.5'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects empty', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts non-empty', () {
      expect(Validators.required('餐饮'), isNull);
    });
  });
}
