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
      styles: [
        css.import(
          'https://fonts.googleapis.com/css2'
          '?family=Noto+Sans+JP:wght@400;500;700'
          '&family=Poppins:wght@400;500;600;700;900'
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
          backgroundColor: deepNavy,
          raw: const {'overflow-x': 'hidden'},
        ),
        css('h1, h2, h3, h4, p').styles(margin: .zero),
      ],
      body: App(),
    ),
  );
}
