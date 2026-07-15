import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/providers/auth_provider.dart';

class CitySelectScreen extends ConsumerStatefulWidget {
  const CitySelectScreen({super.key});

  @override
  ConsumerState<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends ConsumerState<CitySelectScreen> {
  String? _selectedCity;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _cities = [
    {'name': 'Szczecin', 'available': true, 'icon': Icons.location_city},
    {'name': 'Warszawa', 'available': false, 'icon': Icons.lock_outline},
    {'name': 'Kraków', 'available': false, 'icon': Icons.lock_outline},
    {'name': 'Wrocław', 'available': false, 'icon': Icons.lock_outline},
  ];

  Future<void> _onConfirm() async {
    if (_selectedCity == null) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', _selectedCity!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authStateProvider);
    final devLogin = ref.read(devLoginProvider);
    if (authState.value != null || devLogin) {
      context.go('/map');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE30613), Color(0xFFB00010)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(80),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'drivio',
                style: GoogleFonts.poppins(
                  color: AppTheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Wybierz swoje miasto',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Znajdź pułapki egzaminacyjne w swoim mieście',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final isAvailable = city['available'] as bool;
                    final name = city['name'] as String;
                    final isSelected = _selectedCity == name;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () => setState(() => _selectedCity = name)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withAlpha(20)
                              : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? (isSelected
                                          ? AppTheme.primary.withAlpha(30)
                                          : AppTheme.bgDark)
                                    : AppTheme.bgDark.withAlpha(200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                city['icon'] as IconData,
                                color: isAvailable
                                    ? (isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary)
                                    : AppTheme.textSecondary.withAlpha(100),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      color: isAvailable
                                          ? Colors.white
                                          : AppTheme.textSecondary.withAlpha(
                                              150,
                                            ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isAvailable)
                                    Text(
                                      'Wkrótce dostępne',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textSecondary.withAlpha(
                                          150,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedCity != null && !_isLoading
                      ? _onConfirm
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.primary.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Zaczynamy!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
