import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/premium_provider.dart';
import 'package:drivio/providers/settings_provider.dart';
import 'package:drivio/screens/splash/splash_screen.dart';
import 'package:drivio/screens/onboarding/city_select_screen.dart';
import 'package:drivio/screens/auth/login_screen.dart';
import 'package:drivio/screens/auth/register_screen.dart';
import 'package:drivio/screens/map/map_screen.dart';
import 'package:drivio/screens/trap/trap_detail_screen.dart';
import 'package:drivio/screens/trap/add_trap_screen.dart';
import 'package:drivio/screens/school/schools_screen.dart';
import 'package:drivio/screens/school/school_detail_screen.dart';
import 'package:drivio/screens/pro_tips/pro_tips_screen.dart';
import 'package:drivio/screens/exam/exam_registration_screen.dart';
import 'package:drivio/screens/profile/profile_screen.dart';
import 'package:drivio/screens/premium/premium_screen.dart';
import 'package:drivio/screens/legal/terms_screen.dart';
import 'package:drivio/screens/legal/privacy_screen.dart';
import 'package:drivio/screens/ranking/ranking_screen.dart';
import 'package:drivio/screens/admin/admin_moderation_screen.dart';
import 'package:drivio/screens/admin/admin_school_form_screen.dart';
import 'package:drivio/screens/settings/settings_screen.dart';
import 'package:drivio/screens/guides/parking_screen.dart';
import 'package:drivio/screens/guides/car_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);
      final devLogin = ref.read(devLoginProvider);
      final isLoggedIn = authState.value != null || devLogin;
      final isLoading = authState.isLoading && !devLogin;

      if (isLoading) return null;

      final prefs = await SharedPreferences.getInstance();
      final citySelected = prefs.getString('selectedCity');

      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final onSplash = state.matchedLocation == '/';
      final onCitySelect = state.matchedLocation == '/city-select';

      final isPublic =
          onSplash ||
          onCitySelect ||
          loggingIn ||
          state.matchedLocation == '/terms' ||
          state.matchedLocation == '/privacy';

      if (onSplash) return null;

      if (!isLoggedIn) {
        if (isPublic) return null;
        return citySelected == null ? '/city-select' : '/login';
      }

      if (citySelected == null) {
        return onCitySelect ? null : '/city-select';
      }

      if (loggingIn || onCitySelect) return '/map';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/city-select',
        builder: (context, state) => const CitySelectScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/trap/add',
        builder: (context, state) => const AddTrapScreen(),
      ),
      GoRoute(
        path: '/trap/:id',
        builder: (context, state) =>
            TrapDetailScreen(trapId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/schools',
        builder: (context, state) => const SchoolsScreen(),
      ),
      GoRoute(
        path: '/school/:id',
        builder: (context, state) =>
            SchoolDetailScreen(schoolId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pro-tips',
        builder: (context, state) => const ProTipsScreen(),
      ),
      GoRoute(
        path: '/exam',
        builder: (context, state) => const ExamRegistrationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/parking',
        builder: (context, state) => const ParkingScreen(),
      ),
      GoRoute(path: '/car', builder: (context, state) => const CarScreen()),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/ranking',
        builder: (context, state) => const RankingScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminModerationScreen(),
      ),
      GoRoute(
        path: '/admin/school/add',
        builder: (context, state) => const AdminSchoolFormScreen(),
      ),
      GoRoute(
        path: '/admin/school/:id/edit',
        builder: (context, state) =>
            AdminSchoolFormScreen(schoolId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Text(
          'Strona nie istnieje: ${state.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );

  ref.listen(authStateProvider, (_, _) => router.refresh());
  ref.listen(devLoginProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

class DrivioApp extends ConsumerWidget {
  const DrivioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(premiumIapBootstrapProvider);
    final router = ref.watch(_routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Drivio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
