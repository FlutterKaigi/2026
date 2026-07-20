import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/caption_segment.dart';
import 'transcriber.dart';
import 'translator.dart';

/// [Translator] backed by the Gemini `generateContent` REST API
/// (`generativelanguage.googleapis.com`, API-key auth). The model is supplied by
/// configuration so it can be swapped via the `GEMINI_MODEL` env var.
class GeminiTranslator implements Translator {
  GeminiTranslator({
    required this.apiKey,
    this.model = 'gemini-2.5-flash-lite',
    http.Client? client,
    Uri Function(String model)? endpoint,
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? _defaultEndpoint;

  final String apiKey;
  final String model;
  final http.Client _client;
  final Uri Function(String model) _endpoint;

  // The API key goes in the x-goog-api-key header, not the URL: URLs end up in
  // proxy/server logs.
  static Uri _defaultEndpoint(String model) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      );

  static const _systemInstruction =
      'あなたは技術カンファレンス FlutterKaigi の登壇セッションを担当する同時通訳者です。'
      '与えられた発話(原文)を、提供された直近の文脈と用語集を踏まえて自然な日本語(ja)と英語(en)に翻訳してください。'
      'Flutter / Dart の専門用語(例: Widget, Hot Reload, BuildContext)は無理に意訳せず一般的な表記を用います。'
      '出力は {"ja": "...", "en": "..."} という JSON のみとし、余計な説明やコードフェンスを含めないでください。';

  @override
  Future<TranslationResult> translate(
    TranscriptEvent segment,
    List<CaptionSegment> recentContext, {
    String? domainContext,
  }) async {
    final context = recentContext.map((s) => '- ${s.srcText}').join('\n');
    final prompt = StringBuffer()
      ..writeln('# 直近の文脈')
      ..writeln(context.isEmpty ? '(なし)' : context)
      ..writeln()
      ..writeln('# 翻訳対象(原文: ${segment.srcLang})')
      ..writeln(segment.text);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {
            'text': domainContext == null
                ? _systemInstruction
                : '$_systemInstruction\n\n'
                    '# カンファレンス情報(固有名詞・人名・企業名はこの表記を優先すること)\n'
                    '$domainContext',
          },
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt.toString()},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'ja': {'type': 'STRING'},
            'en': {'type': 'STRING'},
          },
          'required': ['ja', 'en'],
        },
      },
    });

    final http.Response res;
    try {
      res = await _client.post(
        _endpoint(model),
        headers: {'content-type': 'application/json', 'x-goog-api-key': apiKey},
        body: body,
      );
    } catch (e) {
      throw TranslationException('gemini request failed: $e');
    }
    if (res.statusCode != 200) {
      throw TranslationException('gemini HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    final text = _extractText(decoded);
    final parsed = jsonDecode(text);
    if (parsed is! Map || parsed['ja'] is! String || parsed['en'] is! String) {
      throw const TranslationException('gemini response did not contain ja/en strings');
    }
    return TranslationResult(ja: parsed['ja'] as String, en: parsed['en'] as String);
  }

  String _extractText(Object? response) {
    if (response is Map) {
      final candidates = response['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = (candidates.first as Map)['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final text = (parts.first as Map)['text'];
            if (text is String) return text;
          }
        }
      }
    }
    throw const TranslationException('gemini response had no text part');
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();
}
