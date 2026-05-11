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
      head: [
        link(rel: 'icon', href: '/favicon.ico', attributes: {'sizes': 'any'}),
        link(rel: 'icon', href: '/favicon.svg', attributes: {'type': 'image/svg+xml'}),
        link(rel: 'apple-touch-icon', href: '/favicon-180.png'),
        link(rel: 'manifest', href: '/manifest.webmanifest'),
        meta(name: 'theme-color', content: colorKeycolorsPrimaryHex),
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
