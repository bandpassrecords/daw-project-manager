import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.1 relative luminance of an opaque sRGB color.
double relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two colors, from 1.0 (identical) to 21.0
/// (black on white). Order does not matter.
///
/// Both colors are assumed opaque — a translucent foreground should be
/// composited over its background with [Color.alphaBlend] first.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Whether [foreground] on [background] clears WCAG AA for body text (4.5:1),
/// or for large text (3:1) when [largeText] is set.
bool meetsWcagAa(Color foreground, Color background, {bool largeText = false}) =>
    contrastRatio(foreground, background) >= (largeText ? 3.0 : 4.5);
