import '../models/caption_segment.dart';
import 'transcriber.dart';

/// Translates a finalized segment into ja/en (always returns both).
abstract interface class Translator {
  Future<TranslationResult> translate(TranscriptEvent segment, List<CaptionSegment> recentContext);
}

/// Result of a translation: Japanese and English renderings.
class TranslationResult {
  const TranslationResult({required this.ja, required this.en});
  final String ja;
  final String en;
}

/// Thrown by a [Translator] when translation fails. The pipeline skips the
/// offending segment and keeps running.
class TranslationException implements Exception {
  const TranslationException(this.message);
  final String message;
  @override
  String toString() => 'TranslationException: $message';
}
