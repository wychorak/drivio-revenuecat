import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/screens/guides/car_screen.dart';
import 'package:drivio/theme/app_theme.dart';

void main() {
  // Every weight is bundled; fail loudly instead of reaching the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  // A phone-wide but very tall view, so the whole lazily built list is laid
  // out at once and no test depends on scroll physics.
  Future<void> pumpCar(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(1080, 15000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: theme, home: const CarScreen()));
    await tester.pump();
  }

  final dark = AppTheme.darkTheme;
  final light = AppTheme.lightTheme;

  const titles = [
    'Światła pozycyjne',
    'Światła mijania',
    'Światła drogowe',
    'Światła hamowania',
    'Światło cofania',
    'Kierunkowskazy',
    'Światła awaryjne',
    'Płyn do spryskiwaczy',
    'Płyn hamulcowy',
    'Olej silnikowy',
    'Płyn chłodniczy',
  ];

  for (final (name, theme) in [('dark', dark), ('light', light)]) {
    testWidgets('lists every light and fluid ($name theme)', (tester) async {
      await pumpCar(tester, theme);

      for (final title in titles) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('every card expands without layout errors ($name theme)', (
      tester,
    ) async {
      await pumpCar(tester, theme);

      for (final title in titles) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      expect(find.byIcon(Icons.zoom_in_rounded), findsNWidgets(titles.length));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('expanding a fluid shows its steps and warning', (tester) async {
    await pumpCar(tester, dark);

    await tester.tap(find.text('Płyn chłodniczy'));
    await tester.pumpAndSettle();

    expect(find.text('Sprawdzamy w różowym zbiorniczku.'), findsOneWidget);
    expect(
      find.text('Nie odkręcamy korka na gorącym silniku!'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a photo opens and closes the zoom view', (tester) async {
    await pumpCar(tester, dark);

    await tester.tap(find.text('Światła drogowe'));
    await tester.pumpAndSettle();
    expect(find.text('Do użycia tylko po zmroku.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.zoom_in_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('Zamknij'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
