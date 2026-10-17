import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:test/test.dart';
import 'package:website/components/linkified_text.dart';

void main() {
  setUpAll(Jaspr.initializeApp);

  group('LinkifiedText', () {
    test('links a long form URL without changing its query or surrounding text', () async {
      const url = 'https://docs.google.com/forms/d/e/exampleFormId/viewform?usp=publish-editor&hl=ja';
      final html = await _render('事前質問はこちら。\n$url\nご参加ください。');

      expect(html, contains('事前質問はこちら。'));
      expect(html, contains('ご参加ください。'));
      expect(html, contains('href="${url.replaceAll('&', '&amp;')}"'));
      expect(html, contains('>${url.replaceAll('&', '&amp;')}</a>'));
      expect(html, contains('target="_blank"'));
      expect(html, contains('rel="noopener noreferrer"'));
      expect('<a '.allMatches(html), hasLength(1));
    });

    test('links multiple HTTP(S) URLs but leaves sentence punctuation outside', () async {
      final html = await _render('https://example.com/ja。 (http://example.com/en). HTTPS://example.com/other!');

      expect('<a '.allMatches(html), hasLength(3));
      expect(html, contains('href="https://example.com/ja"'));
      expect(html, contains('>https://example.com/ja</a>。 ('));
      expect(html, contains('>http://example.com/en</a>). '));
      expect(html, contains('>HTTPS://example.com/other</a>!'));
    });

    test('keeps text without valid HTTP(S) URLs unchanged', () async {
      const text =
          'javascript:alert(1) data:text/html,test ftp://example.com '
          'https:// https:///missing-host https://[invalid]';

      final html = await _render(text);

      expect(html, contains(text));
      expect(html, isNot(contains('<a ')));
      expect((await _render('')).trim(), '<p></p>');
    });

    test('escapes HTML and separates quotes and angle brackets from links', () async {
      final html = await _render(
        '<script>alert("x")</script> <https://example.com/form> "https://example.com/help"',
      );

      expect(html, isNot(contains('<script>')));
      expect(html, contains('&lt;script&gt;'));
      expect('<a '.allMatches(html), hasLength(2));
      expect(html, contains('href="https://example.com/form"'));
      expect(html, contains('>https://example.com/form</a>&gt;'));
      expect(html, contains('href="https://example.com/help"'));
    });
  });
}

Future<String> _render(String text) async {
  final response = await renderComponent(p([LinkifiedText(text)]), standalone: true);
  return utf8.decode(response.body);
}
