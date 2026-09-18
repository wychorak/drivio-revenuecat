import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class CarScreen extends StatelessWidget {
  const CarScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Samochód na egzaminie')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Checklist('Przed ruszeniem', Icons.fact_check_outlined, [
          'Ustaw fotel, zagłówek i lusterka',
          'Zapnij pas i sprawdź drzwi',
          'Sprawdź bieg jałowy oraz hamulec postojowy',
          'Uruchom światła wymagane w danych warunkach',
        ]),
        _Checklist('Obsługa pojazdu', Icons.directions_car_outlined, [
          'Światła: mijania, drogowe, przeciwmgłowe i awaryjne',
          'Płyny: hamulcowy, chłodniczy i spryskiwaczy',
          'Poziom oleju i kontrolki na desce rozdzielczej',
          'Sygnał dźwiękowy i podstawowe wyposażenie',
        ]),
        _Checklist('Podczas jazdy', Icons.route_outlined, [
          'Regularnie obserwuj lusterka',
          'Sygnalizuj manewry odpowiednio wcześnie',
          'Zachowuj odstęp i dostosuj prędkość',
          'Przed manewrem sprawdzaj martwe pole',
        ]),
      ],
    ),
  );
}

class _Checklist extends StatelessWidget {
  const _Checklist(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(item, style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
