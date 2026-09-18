import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/providers/settings_provider.dart';

void main() {
  test('rapid theme changes apply only the final selection', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeModeController();

    await controller.setTheme(ThemeMode.light);
    await controller.setTheme(ThemeMode.system);
    await controller.setTheme(ThemeMode.dark);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(controller.state, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString('settings.themeMode'),
      'dark',
    );
    controller.dispose();
  });
}
