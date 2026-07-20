import '../models/caption_segment.dart';
import 'transcriber.dart';
import 'translator.dart';

/// No-op translator for local development and tests: `ja` is the source text and
/// `en` is `"(en) " + source text`.
class EchoTranslator implements Translator {
  const EchoTranslator();

  @override
  Future<TranslationResult> translate(
    TranscriptEvent segment,
    List<CaptionSegment> recentContext, {
    String? domainContext,
  }) async {
    return TranslationResult(ja: segment.text, en: '(en) ${segment.text}');
  }
}
