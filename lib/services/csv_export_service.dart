import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/category.dart';
import '../models/expense.dart';

/// Lightweight CSV exporter — no extra dependency, just RFC-4180 quoting.
///
/// Writes to the app's documents directory and returns the absolute path
/// of the generated file. Caller is responsible for surfacing it to the
/// user (snackbar, share sheet, etc).
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

  /// `expenses` is rendered in the order given so the file matches what
  /// the user is currently looking at on the history screen.
  Future<File> export({
    required List<Expense> expenses,
    required Map<String, Category> categoryById,
  }) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final DateTime now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final String stamp =
        '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    final File file = File('${dir.path}${Platform.pathSeparator}expenses_$stamp.csv');

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

    await file.writeAsString(buf.toString());
    return file;
  }
}
