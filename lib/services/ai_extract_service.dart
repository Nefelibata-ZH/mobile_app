import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../providers/ai_config_provider.dart';

/// Result of asking the LLM to parse a free-form Chinese sentence into
/// the fields needed to fill the add-expense form. Every field is
/// optional so callers can degrade gracefully — at minimum we want a
/// number; everything else is best-effort.
class AiExtractedExpense {
  const AiExtractedExpense({
    this.kind,
    this.categoryId,
    this.amount,
    this.paymentMethod,
    this.note,
    this.date,
    this.rawTranscript,
    this.modelExplanation,
  });

  /// 'expense' or 'income'. Null when the sentence is ambiguous.
  final String? kind;
  final String? categoryId;
  final double? amount;
  final String? paymentMethod;
  final String? note;
  final DateTime? date;

  /// Original transcript so the UI can show what the user said even if
  /// extraction was partial.
  final String? rawTranscript;

  /// Optional human-readable explanation from the model — surfaced in
  /// debug builds, not shown to users.
  final String? modelExplanation;

  bool get isExpense => kind == 'expense';
  bool get isIncome => kind == 'income';
}

class AiExtractException implements Exception {
  const AiExtractException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Calls an OpenAI-compatible chat-completions endpoint with the user's
/// free-form transcript and returns structured fields. Built around the
/// "JSON object" response_format so we don't have to write a parser.
class AiExtractService {
  const AiExtractService(this.config);

  final AiConfig config;

  /// Available payment methods are passed through as a closed list so
  /// the model can't invent values that the dropdown doesn't accept.
  Future<AiExtractedExpense> extract({
    required String transcript,
    required List<Category> categories,
    required List<String> paymentMethods,
  }) async {
    if (!config.isUsable) {
      throw const AiExtractException('AI 服务未配置或已禁用');
    }
    if (transcript.trim().isEmpty) {
      throw const AiExtractException('没有识别到内容');
    }

    final Uri url =
        Uri.parse('${_normalizedBase()}/chat/completions');
    final List<Map<String, String>> categoryEntries = categories
        .map(
          (Category c) => <String, String>{
            'id': c.id,
            'name': c.name,
            'type': c.type,
          },
        )
        .toList();

    final DateTime now = DateTime.now();
    final String today = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final String systemPrompt = '''
你是一个记账助手。用户会用中文描述一笔记录，你需要从中抽取结构化字段并以严格 JSON 返回。

要求：
1. 只输出 JSON，不要解释。
2. JSON 字段：
   - kind: "expense" 或 "income"。无法判断时根据描述常识默认 "expense"。
   - categoryId: 必须从下方提供的列表中选一个 id，且其 type 与 kind 匹配；如果没有合适的就选最接近的，不允许编造新 id。
   - amount: 数字，正数，单位元，最多两位小数；不要带货币符号。
   - paymentMethod: 必须从给出的 [paymentMethods] 中选一个，无法判断时给 null。
   - note: 简短的一句话描述（不超过 20 字），通常是去掉金额和类别后剩下的部分。
   - date: ISO 8601 日期 (YYYY-MM-DD)；用户没说就用今天。
3. 用户可能说"昨天/前天/上周X/X月X日"，需要你结合"今天"换算成具体日期。

今天是 $today。

可用类别（id / name / type）：
${jsonEncode(categoryEntries)}

可用支付方式：
${jsonEncode(paymentMethods)}
''';

    final Map<String, Object?> body = <String, Object?>{
      'model': config.model,
      'temperature': 0.1,
      'response_format': <String, String>{'type': 'json_object'},
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': transcript.trim()},
      ],
    };

    final http.Response resp;
    try {
      resp = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AiExtractException('请求超时（30 秒），请检查网络');
    } on http.ClientException catch (e) {
      // On Flutter Web "Failed to fetch" almost always means CORS — the
      // LLM provider doesn't return Access-Control-Allow-Origin so the
      // browser blocks the request before it leaves. Native http isn't
      // affected. Surface this as a clear, actionable message instead
      // of the raw network exception.
      if (kIsWeb) {
        throw AiExtractException(
          '浏览器无法跨域调用该 API（CORS 限制）。'
          '请改用桌面端或移动端 App 运行，或自建支持 CORS 的代理。'
          '原始错误：${e.message}',
        );
      }
      throw AiExtractException('网络错误：${e.message}');
    } catch (e) {
      throw AiExtractException('请求失败：$e');
    }

    if (resp.statusCode != 200) {
      final String snippet = utf8.decode(resp.bodyBytes, allowMalformed: true);
      throw AiExtractException(
        '调用失败 (${resp.statusCode}): ${_truncate(snippet, 240)}',
      );
    }

    final Map<String, dynamic> outer =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> choices =
        (outer['choices'] as List<dynamic>? ?? const <dynamic>[]);
    if (choices.isEmpty) {
      throw const AiExtractException('模型未返回任何结果');
    }
    final String content = ((choices.first
                as Map<String, dynamic>)['message'] as Map<String, dynamic>)[
            'content']
        as String;

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw AiExtractException('模型输出不是合法 JSON: ${_truncate(content, 200)}');
    }

    return _validate(parsed, transcript, categories, paymentMethods);
  }

  AiExtractedExpense _validate(
    Map<String, dynamic> j,
    String transcript,
    List<Category> categories,
    List<String> paymentMethods,
  ) {
    String? kind = j['kind'] as String?;
    if (kind != 'income' && kind != 'expense') kind = null;

    double? amount;
    final dynamic rawAmt = j['amount'];
    if (rawAmt is num) {
      amount = rawAmt.toDouble();
    } else if (rawAmt is String) {
      amount = double.tryParse(rawAmt.trim());
    }
    if (amount != null && amount < 0) amount = amount.abs();

    final String? rawCatId = j['categoryId'] as String?;
    String? categoryId;
    if (rawCatId != null) {
      // Accept only if the id actually exists, AND its type matches `kind`
      // when we know `kind`. Guards against the model picking an income
      // category for an expense.
      Category? hit;
      for (final Category c in categories) {
        if (c.id == rawCatId) {
          hit = c;
          break;
        }
      }
      if (hit != null && (kind == null || hit.type == kind)) {
        categoryId = hit.id;
      }
    }

    String? pm = j['paymentMethod'] as String?;
    if (pm != null && !paymentMethods.contains(pm)) pm = null;

    DateTime? date;
    final String? rawDate = j['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    return AiExtractedExpense(
      kind: kind,
      categoryId: categoryId,
      amount: amount,
      paymentMethod: pm,
      note: (j['note'] as String?)?.trim().isEmpty == true
          ? null
          : j['note'] as String?,
      date: date,
      rawTranscript: transcript,
      modelExplanation: j['explanation'] as String?,
    );
  }

  String _normalizedBase() {
    String b = config.baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
