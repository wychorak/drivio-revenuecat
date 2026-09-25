import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/theme/app_theme.dart';

class ExamRegistrationScreen extends StatefulWidget {
  const ExamRegistrationScreen({super.key});

  @override
  State<ExamRegistrationScreen> createState() => _ExamRegistrationScreenState();
}

class _ExamRegistrationScreenState extends State<ExamRegistrationScreen> {
  Future<void> _openWord() async {
    final uri = Uri.parse(AppConfig.wordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rejestracja na egzamin'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _headerCard(),
          const SizedBox(height: 16),
          _section(
            icon: Icons.how_to_reg_rounded,
            iconColor: AppTheme.primary,
            title: 'Jak zapisać się na egzamin',
            children: [
              _step('1', 'Wejdź na stronę WORD Szczecin: word.szczecin.pl'),
              _step('2', 'Kliknij "Rezerwacja terminu egzaminu"'),
              _step('3', 'Zaloguj się lub utwórz konto'),
              _step('4', 'Wybierz kategorię prawa jazdy (np. B)'),
              _step('5', 'Wybierz termin egzaminu teoretycznego'),
              _step('6', 'Wybierz termin egzaminu praktycznego'),
              _step('7', 'Opłać egzamin (patrz niżej)'),
              _step('8', 'Potwierdź rezerwację – otrzymasz email'),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.payments_outlined,
            iconColor: AppTheme.successColor,
            title: 'Jak opłacić prawo jazdy',
            children: [
              _infoItem('Kategoria B — teoria: 59 zł'),
              _infoItem('Kategoria B — praktyka: 239 zł'),
              _infoItem('Cały egzamin kategorii B: 298 zł'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Przelew bankowy:',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _bankRow('Aktualność:', 'cennik od 16 czerwca 2026 r.'),
                    _bankRow(
                      'Weryfikacja:',
                      'sprawdź dane przelewu na stronie WORD przed wpłatą',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.folder_outlined,
            iconColor: AppTheme.routeBlue,
            title: 'Dokumenty do wniosku o PKK',
            children: [
              _infoItem(
                'Wniosek o wydanie PKK (dostępny na miejscu lub online)',
              ),
              _infoItem(
                'Orzeczenie lekarskie stwierdzające brak przeciwwskazań do kierowania',
              ),
              _infoItem('Wyraźna kolorowa fotografia (3,5 cm x 4,5 cm)'),
              _infoItem('Dowód osobisty lub paszport'),
              _infoItem('Pisemna zgoda rodziców (jeśli nie ukończyłeś 18 lat)'),
              _infoItem(
                'Opłata administracyjna: 100,50 zł (za wydanie prawa jazdy)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.credit_card_outlined,
            iconColor: AppTheme.premiumGold,
            title: 'Jak zamówić blankiet prawa jazdy',
            children: [
              _step(
                '1',
                'Po zdanym egzaminie złóż wniosek w urzędzie lub online',
              ),
              _step(
                '2',
                'Udaj się do Wydziału Komunikacji Urzędu Miejskiego w Szczecinie',
              ),
              _step(
                '3',
                'Dostarcz orzeczenie i zdjęcie (jeśli nie było złożone przy PKK)',
              ),
              _step('4', 'Opłać 100,50 zł za wydanie dokumentu'),
              _step('5', 'Prawo jazdy odbierzesz w ciągu 2–4 tygodni'),
              _step(
                '6',
                'Możliwa wysyłka pocztą – zaznacz przy składaniu wniosku',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.checklist_rounded,
            iconColor: AppTheme.primary,
            title: 'Co musisz mieć w dniu egzaminu',
            children: [
              _checkItem('Dowód osobisty lub paszport', true),
              _checkItem('PKK – Profil Kandydata na Kierowcę', true),
              _checkItem('Okulary lub soczewki (jeśli dotyczy)', false),
              _checkItem('Wygodne buty (nie klapki!)', false),
              _checkItem('Naładowany telefon', false),
              _checkItem('Przyjść 15 minut przed czasem', false),
              _checkItem('Wyspany i spokojny', false),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _openWord,
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text(
                'Zapisz się przez WORD Szczecin →',
                style: TextStyle(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(30),
            AppTheme.routeBlue.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Egzamin na prawo jazdy',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Wszystko, co musisz wiedzieć',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppTheme.primary, fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            required ? Icons.check_circle : Icons.check_circle_outline,
            color: required ? AppTheme.primary : AppTheme.successColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: required
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: required ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Wymagane',
                style: GoogleFonts.poppins(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
