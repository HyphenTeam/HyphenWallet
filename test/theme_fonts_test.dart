import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_wallet/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wallet themes use the two font families in the asset bundle', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final families = {
      for (final entry in manifest) entry['family']: entry['fonts'] as List,
    };
    for (final theme in [buildHyphenTheme(), buildHyphenDarkTheme()]) {
      final style = theme.textTheme.bodyMedium!;
      expect(style.fontFamily, 'GoogleSans');
      expect(style.fontFamilyFallback, contains('HarmonyOSSans'));
    }
    expect(
      families['GoogleSans']!.single['asset'],
      endsWith('/GoogleSans-Variable.ttf'),
    );
    expect(families['HarmonyOSSans']!.map((font) => font['weight']), [
      400,
      500,
      700,
    ]);
  });
}
