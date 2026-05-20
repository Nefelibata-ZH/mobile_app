import 'csv_export_result.dart';

/// Platform-specific saver. The real implementation is selected via
/// conditional imports in [csv_export_service.dart].
Future<CsvExportResult> saveCsv(String filename, String contents) {
  throw UnsupportedError('No CSV saver registered for this platform.');
}
