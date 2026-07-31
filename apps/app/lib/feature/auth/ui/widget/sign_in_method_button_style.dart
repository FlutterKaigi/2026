import 'package:flutter/material.dart';

/// Sign-in method buttons share these dimensions and typography so provider
/// branding does not make one option look more prominent than another.
const signInMethodButtonHeight = 48.0;

/// Maximum width supported by the Sign in with Apple web button.
const signInMethodButtonMaxWidth = 375.0;

const signInMethodButtonIconInset = 12.0;
const signInMethodButtonIconSize = 18.0;
// The Apple glyph has more internal whitespace than the image and mail icons.
const signInMethodAppleIconSize = 22.0;
const signInMethodButtonBorderRadius = BorderRadius.all(Radius.circular(8));

const signInMethodButtonLabelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 20 / 14,
  letterSpacing: 0.1,
);
