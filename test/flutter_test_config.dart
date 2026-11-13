import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file.
///
/// Screens use Poppins from google_fonts, which loads the bundled font files
/// asynchronously. Without this, the first test in a file can end before the
/// font arrives; the late "fonts changed" relayout then fails the test with
/// "An animation is still running even after the widget tree was disposed"
/// (seen on Flutter 3.50). Loading the fonts up front makes that impossible.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The weights bundled in assets/google_fonts/ (bundled_fonts_test keeps
  // that folder in step with the weights used in lib/).
  for (final weight in const [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.poppins(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
  await testMain();
}
