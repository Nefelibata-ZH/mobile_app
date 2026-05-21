import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/ai_config_provider.dart';
import '../providers/category_provider.dart';
import '../services/ai_extract_service.dart';
import '../services/speech_to_text_service.dart';
import '../utils/constants.dart';

/// Bottom sheet that walks the user through speak → transcribe → AI
/// extraction. Returns an [AiExtractedExpense] when the user confirms;
/// returns null when they cancel.
///
/// Three internal phases drive the UI: idle (tap-to-start), listening
/// (live transcript), processing (waiting on the model). All errors get
/// surfaced inline so the sheet stays modal until the user dismisses.
class VoiceCaptureSheet extends ConsumerStatefulWidget {
  const VoiceCaptureSheet({super.key});

  @override
  ConsumerState<VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

enum _Phase { idle, listening, processing, error }

class _VoiceCaptureSheetState extends ConsumerState<VoiceCaptureSheet> {
  final SpeechToTextService _speech = SpeechToTextService();
  _Phase _phase = _Phase.idle;
  String _transcript = '';
  String? _error;

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _error = null;
    });
    final bool ok = await _speech.ensureReady(
      onError: (String e) {
        if (mounted) {
          setState(() {
            _phase = _Phase.error;
            _error = '语音引擎不可用：$e';
          });
        }
      },
    );
    if (!ok) {
      if (mounted && _phase != _Phase.error) {
        setState(() {
          _phase = _Phase.error;
          _error = '语音引擎不可用，请检查麦克风和语音识别权限';
        });
      }
      return;
    }
    await _speech.start(
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
      },
    );
  }

  Future<void> _stopAndExtract() async {
    await _speech.stop();
    if (!mounted) return;
    if (_transcript.trim().isEmpty) {
      setState(() {
        _phase = _Phase.error;
        _error = '没有识别到内容，请重试';
      });
      return;
    }
    setState(() => _phase = _Phase.processing);

    final AiConfig cfg = ref.read(aiConfigProvider);
    final List<Category> categories = ref.read(categoryListProvider);
    try {
      final AiExtractedExpense result = await AiExtractService(cfg).extract(
        transcript: _transcript,
        categories: categories,
        paymentMethods: AppConstants.paymentMethods,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on AiExtractException catch (e) {
      if (!mounted) return;
      // Even when extraction fails, hand the raw transcript back so the
      // user doesn't lose their words — caller drops it into the note
      // field and the user can correct manually.
      setState(() {
        _phase = _Phase.error;
        _error = '识别失败：${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = '未知错误：$e';
      });
    }
  }

  void _useTranscriptOnly() {
    Navigator.of(context).pop(
      AiExtractedExpense(rawTranscript: _transcript),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '语音记账',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _hint(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMicButton(context),
            const SizedBox(height: 20),
            _buildTranscriptCard(context),
            if (_phase == _Phase.error && _error != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.error_outline, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  String _hint() {
    switch (_phase) {
      case _Phase.idle:
        return '说出"昨天午饭花了 35 元，微信支付"这样的句子';
      case _Phase.listening:
        return '正在聆听… 说完点中间停止';
      case _Phase.processing:
        return '正在调用 AI 识别字段，请稍候';
      case _Phase.error:
        return '出现错误，可重试或仅保留备注';
    }
  }

  Widget _buildMicButton(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool listening = _phase == _Phase.listening;
    final bool processing = _phase == _Phase.processing;

    final Color bg = listening
        ? cs.error
        : processing
            ? cs.surfaceContainerHighest
            : cs.primary;

    return Center(
      child: Material(
        shape: const CircleBorder(),
        color: bg,
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: processing
              ? null
              : (listening ? _stopAndExtract : _startListening),
          child: SizedBox(
            width: 96,
            height: 96,
            child: processing
                ? const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    listening ? Icons.stop : Icons.mic,
                    size: 40,
                    color: listening ? cs.onError : cs.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(BuildContext context) {
    final String text = _transcript.isEmpty
        ? (_phase == _Phase.idle ? '点中间的麦克风开始录音' : '…')
        : _transcript;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: _transcript.isEmpty
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool hasText = _transcript.trim().isNotEmpty;
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('取消'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_phase == _Phase.error && hasText)
          Expanded(
            child: OutlinedButton(
              onPressed: _useTranscriptOnly,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('仅用备注'),
              ),
            ),
          ),
      ],
    );
  }
}
