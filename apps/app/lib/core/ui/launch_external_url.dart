import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Function used to open an external URI.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

/// Attempts to open [uri] outside the app, returning whether it launched.
///
/// Swallows any exception from [launcher] (e.g. no app can handle it) as a
/// `false` result, so callers can fall back to something else (a failure
/// [SnackBar], copying the value) without a try/catch of their own.
Future<bool> tryLaunchExternalUrl(Uri uri, {ExternalUrlLauncher? launcher}) async {
  try {
    return await (launcher ?? _launchWithPlatform)(uri);
  } on Object {
    return false;
  }
}

/// Opens [uri] outside the app and reports both false results and exceptions.
Future<void> launchExternalUrl(
  BuildContext context, {
  required Uri uri,
  required String failureMessage,
  ExternalUrlLauncher? launcher,
}) async {
  final launched = await tryLaunchExternalUrl(uri, launcher: launcher);
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
