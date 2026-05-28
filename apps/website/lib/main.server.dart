/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

import 'package:jaspr/dom.dart';
// Server-specific Jaspr import.
import 'package:jaspr/server.dart';

// Imports the [App] component.
import 'app.dart';
import 'constants/build_config.dart';
import 'constants/generated_tokens.dart';
import 'constants/theme.dart';
// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  runApp(
    Document(
      title: 'FlutterKaigi 2026',
      base: baseHref,
      head: [
        if (isPreviewBuild) meta(name: 'robots', content: 'noindex,nofollow'),
        link(rel: 'icon', href: 'favicon.ico', attributes: {'sizes': 'any'}),
        link(rel: 'icon', href: 'favicon.svg', attributes: {'type': 'image/svg+xml'}),
        link(rel: 'apple-touch-icon', href: 'favicon-180.png'),
        link(rel: 'manifest', href: 'manifest.webmanifest'),
        meta(name: 'theme-color', content: colorKeycolorsPrimaryHex),
        // OGP
        meta(
          attributes: {
            'property': 'og:title',
            'content': 'FlutterKaigi 2026',
          },
        ),
        meta(
          attributes: {
            'property': 'og:description',
            'content':
                '2026年、日本国内でFlutterをメインに扱う技術カンファレンス。'
                'FlutterやDartの深い知見を持つ開発者によるセッションを多数企画します。',
          },
        ),
        meta(
          attributes: {
            'property': 'og:image',
            'content': 'https://2026.flutterkaigi.jp/images/ogp.png',
          },
        ),
        meta(
          attributes: {
            'property': 'og:type',
            'content': 'website',
          },
        ),
        meta(
          attributes: {
            'property': 'og:url',
            'content': 'https://2026.flutterkaigi.jp/',
          },
        ),
        meta(name: 'twitter:card', content: 'summary_large_image'),
        meta(name: 'twitter:site', content: '@FlutterKaigi'),
        script(
          src: 'https://www.googletagmanager.com/gtag/js?id=G-0FZ58E7XNG',
          async: true,
        ),
        // ignore: prefer_html_methods
        const DomComponent(
          tag: 'script',
          children: [
            RawText('''
window.dataLayer = window.dataLayer || [];
function gtag() {
  dataLayer.push(arguments);
}
gtag('js', new Date());
gtag('config', 'G-0FZ58E7XNG');
'''),
          ],
        ),
      ],
      styles: [
        css.import(
          'https://fonts.googleapis.com/css2'
          '?family=Noto+Sans+JP:wght@400;500;700'
          '&family=Poppins:wght@400;500;600;700;900'
          '&display=swap',
        ),
        css.import(
          'https://fonts.googleapis.com/css2'
          '?family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900'
          '&display=swap',
        ),
        css('*, *::before, *::after').styles(
          boxSizing: .borderBox,
        ),
        css('html, body').styles(
          width: 100.percent,
          minHeight: 100.vh,
          padding: .zero,
          margin: .zero,
          fontFamily: uiFontFamily,
          color: onBrand,
          backgroundColor: surface,
          raw: const {'overflow-x': 'hidden'},
        ),
        css('h1, h2, h3, h4, p').styles(margin: .zero),
      ],
      body: App(),
    ),
  );
}
