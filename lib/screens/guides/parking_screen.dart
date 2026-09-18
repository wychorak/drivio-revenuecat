import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Parkowanie')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Guide('Parkowanie równoległe', Icons.swap_horiz_rounded, [
          'Ustaw auto równolegle, około 0,5–1 m od pojazdu obok.',
          'Włącz kierunkowskaz i sprawdź lusterka oraz martwe pole.',
          'Cofaj pod kątem około 45°, następnie wyprostuj koła.',
          'Zakończ równolegle do krawężnika i zabezpiecz pojazd.',
        ]),
        _Guide('Parkowanie prostopadłe', Icons.local_parking_rounded, [
          'Zwolnij przed miejscem i zasygnalizuj zamiar manewru.',
          'Kontroluj oba lusterka i odstęp od sąsiednich pojazdów.',
          'Wyśrodkuj samochód między liniami stanowiska.',
          'Przed zakończeniem sprawdź położenie auta i otoczenie.',
        ]),
        _Guide('Parkowanie skośne', Icons.turn_slight_right_rounded, [
          'Podjedź szeroko i skręć płynnie w stronę stanowiska.',
          'Obserwuj narożniki pojazdu oraz pieszych.',
          'Wyprostuj koła przed całkowitym zatrzymaniem.',
        ]),
      ],
    ),
  );
}

class _Guide extends StatelessWidget {
  const _Guide(this.title, this.icon, this.steps);
  final String title;
  final IconData icon;
  final List<String> steps;

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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
