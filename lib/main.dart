import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/firebase_options.dart';
import 'app.dart';
import 'services/revenuecat_service.dart';
import 'services/session_preference_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await initializeDateFormatting('pl', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setLanguageCode('pl');
  await SessionPreferenceService.enforceOnStartup();
  await _activateAppCheck();
  await RevenueCatService.instance.initialize();
  runApp(const ProviderScope(child: DrivioApp()));
}

Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (error, stackTrace) {
    // Enable enforcement only after monitoring valid production traffic.
    debugPrint('Firebase App Check activation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
