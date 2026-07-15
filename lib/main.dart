import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/firebase_options.dart';
import 'app.dart';
import 'services/revenuecat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await initializeDateFormatting('pl', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RevenueCatService.instance.initialize();
  runApp(const ProviderScope(child: DrivioApp()));
}
