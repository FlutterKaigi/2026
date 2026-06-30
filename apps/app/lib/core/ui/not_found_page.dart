import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Displayed when the router cannot match the requested location.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.notFound.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(t.notFound.description)),
      ),
    );
  }
}
