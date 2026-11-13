import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// google_fonts downloads any Poppins weight that is not bundled, so the app
/// would need the internet for it. Every weight used in lib/ must ship.
void main() {
  const fileByWeight = {
    100: 'Thin',
    200: 'ExtraLight',
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
    800: 'ExtraBold',
    900: 'Black',
  };

  test('every Poppins weight used in lib/ is bundled', () {
    final used = <int>{400, 500}; // Material text theme defaults.
    final pattern = RegExp(r'FontWeight\.(w(\d)00|bold|normal)\b');
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in pattern.allMatches(file.readAsStringSync())) {
        used.add(switch (m.group(1)) {
          'bold' => 700,
          'normal' => 400,
          _ => int.parse(m.group(2)!) * 100,
        });
      }
    }

    final missing = [
      for (final weight in used)
        if (!File(
          'assets/google_fonts/Poppins-${fileByWeight[weight]}.ttf',
        ).existsSync())
          'Poppins-${fileByWeight[weight]}.ttf',
    ];
    expect(missing, isEmpty);
  });
}
