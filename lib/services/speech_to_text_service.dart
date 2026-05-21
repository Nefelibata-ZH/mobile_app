import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around the [speech_to_text] plugin.
///
/// The plugin exposes a callback-based API; this service serializes
/// init/start/stop into something a `ConsumerState` can drive without
/// keeping platform plumbing in the widget. Caller passes a single
/// listener that gets all partial + final transcript updates and lets
/// us surface live text on screen as the user speaks.
class SpeechToTextService {
  SpeechToTextService();

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;

  bool get isListening => _stt.isListening;
  bool get isAvailable => _stt.isAvailable;

  /// Returns true when the platform speech engine is ready and the user
  /// has granted mic + speech-recognition permission. Call before
  /// [start]; it's cheap to invoke repeatedly because [stt.SpeechToText]
  /// caches the initialization itself.
  Future<bool> ensureReady({
    void Function(String error)? onError,
  }) async {
    if (_initialized && _stt.isAvailable) return true;
    try {
      _initialized = await _stt.initialize(
        onError: (Object e) {
          // The plugin's own error type doesn't expose a clean message
          // across platforms; toString gives us "errorPermission" /
          // "error_no_match" etc which is enough for the UI to surface.
          onError?.call(e.toString());
        },
        onStatus: (String status) {
          debugPrint('SpeechToText status: $status');
        },
      );
      return _initialized;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }

  /// `localeId` defaults to zh_CN since the rest of the app is Chinese
  /// only. The plugin falls back to the device locale if the requested
  /// one isn't installed.
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'zh_CN',
  }) async {
    if (!_initialized) {
      final bool ok = await ensureReady();
      if (!ok) return;
    }
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        onResult(r.recognizedWords, r.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
      localeId: localeId,
    );
  }

  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> cancel() async {
    if (_stt.isListening) await _stt.cancel();
  }
}
