import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../logging.dart';
import 'audio_segmenter.dart';
import 'transcriber.dart';
import 'wav.dart';

/// [Transcriber] backed by Gemini audio understanding (`generateContent` REST,
/// API-key auth) — real speech recognition with nothing but a `GEMINI_API_KEY`.
///
/// Audio is cut into utterances by [AudioSegmenter] (silence-based VAD); each
/// segment is wrapped as WAV and transcribed in one request, so there are no
/// interim events — only finals, roughly one to two seconds after each pause.
/// Segments are transcribed sequentially to preserve caption order; incoming
/// audio simply buffers while a request is in flight. Good enough for local
/// verification; the production path remains streaming Speech-to-Text v2.
class GeminiTranscriber implements Transcriber {
  GeminiTranscriber({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    http.Client? client,
    Uri Function(String model)? endpoint,
    AudioSegmenter Function()? segmenterFactory,
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? _defaultEndpoint,
        _segmenterFactory = segmenterFactory ?? AudioSegmenter.new;

  final String apiKey;
  final String model;
  final http.Client _client;
  final Uri Function(String model) _endpoint;
  final AudioSegmenter Function() _segmenterFactory;

  // The API key goes in the x-goog-api-key header, not the URL: URLs end up in
  // proxy/server logs.
  static Uri _defaultEndpoint(String model) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      );

  static const _systemInstruction = 'あなたは音声書き起こしエンジンです。'
      '添付音声は技術カンファレンス FlutterKaigi の登壇の一部です。'
      '話された言語のまま一字一句書き起こしてください(翻訳しないこと)。'
      'フィラー(「えー」「あの」など)は省いて構いません。'
      'Flutter / Dart の専門用語(Widget, Hot Reload, Riverpod など)は一般的な表記を用います。'
      '出力は {"text": "...", "lang": "<ISO 639-1>"} の JSON のみとし、'
      '明瞭な発話が含まれない場合は {"text": "", "lang": ""} を返してください。';

  @override
  Stream<TranscriptEvent> transcribe(
    Stream<Uint8List> audio, {
    required String sourceLang,
    String? domainContext,
  }) async* {
    final segmenter = _segmenterFactory();
    await for (final chunk in audio) {
      for (final segment in segmenter.addChunk(chunk)) {
        final event = await _transcribeSegment(segment, sourceLang, domainContext);
        if (event != null) yield event;
      }
    }
    final last = segmenter.flush();
    if (last != null) {
      final event = await _transcribeSegment(last, sourceLang, domainContext);
      if (event != null) yield event;
    }
  }

  /// Transcribes one segment; returns null (and keeps the stream alive) on API
  /// errors or silence.
  Future<TranscriptEvent?> _transcribeSegment(AudioSegment segment, String sourceLang, String? domainContext) async {
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {
            'text': domainContext == null
                ? _systemInstruction
                : '$_systemInstruction\n\n'
                    '# カンファレンス情報(固有名詞はこの表記を優先すること)\n'
                    '$domainContext',
          },
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '想定言語: $sourceLang(別の言語であればその言語のまま書き起こし、lang に実際の言語を入れてください)'},
            {
              'inlineData': {
                'mimeType': 'audio/wav',
                'data': base64Encode(pcm16ToWav(segment.pcm)),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'text': {'type': 'STRING'},
            'lang': {'type': 'STRING'},
          },
          'required': ['text', 'lang'],
        },
      },
    });

    try {
      final res = await _client.post(
        _endpoint(model),
        headers: {'content-type': 'application/json', 'x-goog-api-key': apiKey},
        body: body,
      );
      if (res.statusCode != 200) {
        logEvent('transcribe_error', {'status': res.statusCode, 'body': res.body}, 'error');
        return null;
      }
      final parsed = jsonDecode(_extractText(jsonDecode(res.body)));
      if (parsed is! Map || parsed['text'] is! String) {
        logEvent('transcribe_error', {'error': 'response did not contain a text string'}, 'error');
        return null;
      }
      final text = (parsed['text'] as String).trim();
      if (text.isEmpty) return null;
      final lang = parsed['lang'];
      return TranscriptEvent(
        text: text,
        isFinal: true,
        startMs: segment.startMs,
        endMs: segment.endMs,
        srcLang: lang is String && lang.isNotEmpty ? lang : sourceLang.split('-').first,
      );
    } catch (e) {
      logEvent('transcribe_error', {'error': '$e'}, 'error');
      return null;
    }
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
    throw const FormatException('gemini response had no text part');
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();
}
