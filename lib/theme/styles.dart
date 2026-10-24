import 'package:flutter/painting.dart';

class AStyles {
  static const knownTitleText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle unknownTitleText = knownTitleText;

  static void updateStylesForLocale(String languageCode) {
    final smcp = languageCode != 'el';
    unknownTitleText = smcp ? knownTitleText : knownTitleText.copyWith(fontFeatures: []);
  }

  static const embossShadows = [
    Shadow(
      color: Color(0xFF000000),
      offset: Offset(0.5, 1.0),
    ),
  ];
}
