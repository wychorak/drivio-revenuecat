import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/providers/settings_provider.dart';
import 'package:drivio/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

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

  test('light and dark list tile styles interpolate without assertions', () {
    final light = AppTheme.lightTheme.listTileTheme;
    final dark = AppTheme.darkTheme.listTileTheme;

    expect(light.titleTextStyle, isNotNull);
    expect(dark.titleTextStyle, isNotNull);
    expect(light.titleTextStyle!.inherit, dark.titleTextStyle!.inherit);
    expect(light.subtitleTextStyle!.inherit, dark.subtitleTextStyle!.inherit);

    expect(
      () => TextStyle.lerp(light.titleTextStyle, dark.titleTextStyle, 0.5),
      returnsNormally,
    );
  });
}
