import 'package:flutter/material.dart';

/// Reusable gradients from the FlutterKaigi visual identity.
abstract final class AppGradients {
  static const brand = LinearGradient(
    colors: [
      Color(0xFFFF0055),
      Color(0xFF6200EA),
      Color(0xFF6200EA),
      Color(0xFF001155),
    ],
    stops: [0, 0.4, 0.6, 1],
  );
}
