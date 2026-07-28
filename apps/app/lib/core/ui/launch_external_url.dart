import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Function used to open an external URI.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

/// Opens [uri] outside the app and reports both false results and exceptions.
Future<void> launchExternalUrl(
  BuildContext context, {
  required Uri uri,
  required String failureMessage,
  ExternalUrlLauncher? launcher,
}) async {
  var launched = false;
  try {
    launched = await (launcher ?? _launchWithPlatform)(uri);
  } on Object {
    launched = false;
  }

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage)),
    );
  }
}

Future<bool> _launchWithPlatform(Uri uri) => launchUrl(
  uri,
  mode: LaunchMode.externalApplication,
);
