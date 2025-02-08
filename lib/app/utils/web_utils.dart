// lib/app/utils/web_utils.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Abre uma URL em uma nova aba.
void openUrl(String url) {
  html.window.open(url, "_blank");
}