import 'dart:convert';
import 'dart:html' as html;

import 'csv_export_result.dart';

/// Web saver — builds a Blob from the UTF-8 bytes and triggers a
/// browser download via a synthetic anchor click. The browser owns the
/// final save location, so we report only the suggested filename.
Future<CsvExportResult> saveCsv(String filename, String contents) async {
  final List<int> bytes = utf8.encode(contents);
  final html.Blob blob = html.Blob(<List<int>>[bytes], 'text/csv');
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return CsvExportResult(location: filename, savedToDisk: false);
}
