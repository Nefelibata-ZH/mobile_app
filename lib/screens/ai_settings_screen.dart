import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/ai_config_provider.dart';

/// Per-route screen for editing the OpenAI-compatible endpoint used by
/// voice journaling. Lives under `/settings/ai`.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late bool _enabled;
  bool _showKey = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final AiConfig cfg = ref.read(aiConfigProvider);
    _enabled = cfg.enabled;
    _baseUrl = TextEditingController(text: cfg.baseUrl);
    _apiKey = TextEditingController(text: cfg.apiKey);
    _model = TextEditingController(text: cfg.model);
    _baseUrl.addListener(_markDirty);
    _apiKey.addListener(_markDirty);
    _model.addListener(_markDirty);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    await ref.read(aiConfigProvider.notifier).update(
          AiConfig(
            enabled: _enabled,
            baseUrl: _baseUrl.text.trim(),
            apiKey: _apiKey.text.trim(),
            model: _model.text.trim().isEmpty
                ? AiConfig.empty.model
                : _model.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 语音记账'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _dirty ? _save : null,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Card(
            child: SwitchListTile(
              value: _enabled,
              onChanged: (bool v) => setState(() {
                _enabled = v;
                _dirty = true;
              }),
              title: const Text('启用语音记账'),
              subtitle: const Text(
                '关闭后记一笔页面不显示麦克风按钮',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'OpenAI 兼容接口配置',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            obscureText: !_showKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: const InputDecoration(
              labelText: '模型名',
              hintText: 'gpt-4o-mini',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 6),
                      Text('使用说明',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• API Key 仅保存在本机的安全存储里，不会随数据导出泄露\n'
                    '• Base URL 默认指向 OpenAI，可改为兼容接口（例如 Azure / 自建代理）\n'
                    '• 推荐使用 gpt-4o-mini，单次抽取成本约 ¥0.001\n'
                    '• 在记一笔页面顶部点击麦克风开始录音，识别后预填表单等你确认',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
