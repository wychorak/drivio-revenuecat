import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/screens/exam/exam_registration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Tall view so the whole list is laid out without scrolling. Plain themes
  // stand in for AppTheme, whose Poppins weights are fetched at runtime.
  Future<void> pumpExam(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(1080, 15000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: theme, home: const ExamRegistrationScreen()),
    );
    await tester.pump();
  }

  for (final (name, theme) in [
    ('dark', ThemeData(brightness: Brightness.dark)),
    ('light', ThemeData(brightness: Brightness.light)),
  ]) {
    testWidgets('shows licence blank and PKK release steps ($name)', (
      tester,
    ) async {
      await pumpExam(tester, theme);

      expect(
        find.text('Zamówienie blankietu po zdanym egzaminie (online)'),
        findsOneWidget,
      );
      expect(find.text('52 1020 4795 0000 9702 0277 8470'), findsOneWidget);
      expect(find.text('Opłata za wydanie prawa jazdy kat. B'), findsOneWidget);
      expect(find.text('ekancelaria@um.szczecin.pl'), findsOneWidget);
      expect(
        find.text('Egzamin w innym mieście – zwolnienie PKK'),
        findsOneWidget,
      );
      expect(find.text('sekretariat@word.szczecin.pl'), findsOneWidget);
      expect(find.text('Pobierz formularz (PDF)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('copying the account number copies digits only', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpExam(tester, ThemeData(brightness: Brightness.dark));
    await tester.tap(find.byTooltip('Kopiuj: Numer konta'));
    await tester.pump();

    expect(copied, '52102047950000970202778470');
    expect(find.textContaining('Skopiowano'), findsOneWidget);
  });
}
