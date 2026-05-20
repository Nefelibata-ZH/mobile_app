import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'csv_export_result.dart';

/// Native saver — writes to the app's documents directory and falls back
/// to the user's Documents folder (or the system temp dir) when the
/// path_provider plugin isn't registered for the current build.
Future<CsvExportResult> saveCsv(String filename, String contents) async {
  final Directory dir = await _resolveDir();
  final File file =
      File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(contents);
  return CsvExportResult(location: file.path, savedToDisk: true);
}

Future<Directory> _resolveDir() async {
  try {
    return await getApplicationDocumentsDirectory();
  } on MissingPluginException {
    if (Platform.isWindows) {
      final String? user = Platform.environment['USERPROFILE'];
      if (user != null) {
        final Directory d = Directory('$user\\Documents');
        if (await d.exists()) return d;
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final String? home = Platform.environment['HOME'];
      if (home != null) {
        final Directory d = Directory('$home/Documents');
        if (await d.exists()) return d;
      }
    }
    return Directory.systemTemp;
  }
}
