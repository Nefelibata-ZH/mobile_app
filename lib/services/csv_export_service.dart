import '../models/category.dart';
import '../models/expense.dart';
import 'csv_export_result.dart';
import 'csv_saver_stub.dart'
    if (dart.library.io) 'csv_saver_io.dart'
    if (dart.library.html) 'csv_saver_web.dart';

/// Lightweight CSV exporter — no extra dependency, just RFC-4180 quoting.
///
/// Delegates the actual save to a platform-specific saver picked via
/// conditional imports: `dart:io` writes to the documents directory,
/// `dart:html` triggers a browser download. Caller surfaces the result
/// to the user (snackbar, share sheet, etc).
class CsvExportService {
  const CsvExportService();

  /// Always wrap in quotes and escape internal quotes so locale-specific
  /// CSV viewers (Excel zh-CN in particular) handle commas, line breaks,
  /// and the leading minus sign in amounts cleanly.
  String _escape(Object? value) {
    final String s = value?.toString() ?? '';
    return '"${s.replaceAll('"', '""')}"';
  }

  String _row(List<Object?> cells) =>
      cells.map(_escape).join(',');

  String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  String _filename(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    final String stamp =
        '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'expenses_$stamp.csv';
  }

  /// `expenses` is rendered in the order given so the file matches what
  /// the user is currently looking at on the history screen.
  Future<CsvExportResult> export({
    required List<Expense> expenses,
    required Map<String, Category> categoryById,
  }) async {
    final StringBuffer buf = StringBuffer();
    // UTF-8 BOM so Excel on Windows opens the file with the right
    // encoding instead of mangling Chinese characters.
    buf.write('﻿');
    buf.writeln(_row(<Object?>[
      '日期',
      '类型',
      '类别',
      '金额',
      '支付方式',
      '备注',
    ]));
    for (final Expense e in expenses) {
      final Category? c = categoryById[e.category];
      final bool isIncome = e.amount >= 0;
      buf.writeln(_row(<Object?>[
        _date(e.date),
        isIncome ? '收入' : '支出',
        c?.name ?? e.category,
        e.amount.abs().toStringAsFixed(2),
        e.paymentMethod,
        e.note,
      ]));
    }

    return saveCsv(_filename(DateTime.now()), buf.toString());
  }
}
