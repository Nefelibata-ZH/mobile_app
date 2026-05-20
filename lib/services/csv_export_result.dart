/// Outcome of a CSV export, abstracted so the caller doesn't need to know
/// whether a real file was written (native) or a browser download was
/// triggered (web).
class CsvExportResult {
  const CsvExportResult({required this.location, required this.savedToDisk});

  /// On native this is the absolute file path. On web it's the suggested
  /// filename — the actual download location is whatever the browser
  /// chose, so we can't surface a path.
  final String location;

  /// True when [location] points at a file the user can open. False on
  /// web where the file is handed straight to the browser.
  final bool savedToDisk;
}
