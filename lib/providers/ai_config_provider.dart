import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Settings for the OpenAI-compatible chat-completions endpoint used by
/// the voice journaling feature. Loaded once at app start and re-saved
/// on every edit. The API key is stored in [FlutterSecureStorage] and
/// never written into Hive so a Hive export can't leak it.
class AiConfig {
  const AiConfig({
    required this.enabled,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  /// Default sentinel — used until the user opens settings the first time.
  static const AiConfig empty = AiConfig(
    enabled: false,
    baseUrl: 'https://api.openai.com/v1',
    apiKey: '',
    model: 'gpt-4o-mini',
  );

  final bool enabled;
  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isUsable => enabled && apiKey.isNotEmpty && baseUrl.isNotEmpty;

  AiConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    return AiConfig(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

class AiConfigNotifier extends StateNotifier<AiConfig> {
  AiConfigNotifier(this._storage) : super(AiConfig.empty);

  final FlutterSecureStorage _storage;

  static const String _kEnabled = 'ai_enabled';
  static const String _kBaseUrl = 'ai_base_url';
  static const String _kApiKey = 'ai_api_key';
  static const String _kModel = 'ai_model';

  Future<void> load() async {
    try {
      final String? enabled = await _storage.read(key: _kEnabled);
      final String? baseUrl = await _storage.read(key: _kBaseUrl);
      final String? apiKey = await _storage.read(key: _kApiKey);
      final String? model = await _storage.read(key: _kModel);
      state = AiConfig(
        enabled: enabled == 'true',
        baseUrl:
            (baseUrl == null || baseUrl.isEmpty) ? AiConfig.empty.baseUrl : baseUrl,
        apiKey: apiKey ?? '',
        model: (model == null || model.isEmpty) ? AiConfig.empty.model : model,
      );
    } catch (e) {
      // Some Linux/Windows setups lack a secret service. Keep the in-memory
      // default so the rest of the app still works.
      debugPrint('AiConfig load failed: $e');
    }
  }

  Future<void> update(AiConfig next) async {
    state = next;
    try {
      await _storage.write(key: _kEnabled, value: next.enabled.toString());
      await _storage.write(key: _kBaseUrl, value: next.baseUrl);
      await _storage.write(key: _kApiKey, value: next.apiKey);
      await _storage.write(key: _kModel, value: next.model);
    } catch (e) {
      debugPrint('AiConfig save failed: $e');
    }
  }
}

final Provider<FlutterSecureStorage> _secureStorageProvider =
    Provider<FlutterSecureStorage>((Ref ref) => const FlutterSecureStorage());

final StateNotifierProvider<AiConfigNotifier, AiConfig> aiConfigProvider =
    StateNotifierProvider<AiConfigNotifier, AiConfig>(
  (Ref ref) => AiConfigNotifier(ref.watch(_secureStorageProvider)),
);
