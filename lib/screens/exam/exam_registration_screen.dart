import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivio/services/analytics_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/theme/app_theme.dart';

// Ordering the licence blank online in Szczecin.
const _licenceFee = '100 zł';
const _licenceAccount = '52102047950000970202778470';
const _licenceAccountDisplay = '52 1020 4795 0000 9702 0277 8470';
const _licenceTransferTitle = 'Opłata za wydanie prawa jazdy kat. B';
const _cityOfficeEmail = 'ekancelaria@um.szczecin.pl';
const _licenceEmailSubject = 'Imię i nazwisko – numer PKK';

// Releasing the PKK to take the exam in another city.
const _wordOfficeEmail = 'sekretariat@word.szczecin.pl';
const _pkkReleaseFormUrl =
    'https://word.szczecin.pl/wp-content/uploads/2021/09/zwolnienie-pkk_v202109.pdf';

class ExamRegistrationScreen extends StatefulWidget {
  const ExamRegistrationScreen({super.key});

  @override
  State<ExamRegistrationScreen> createState() => _ExamRegistrationScreenState();
}

class _ExamRegistrationScreenState extends State<ExamRegistrationScreen> {
  Future<void> _openWord() async {
    AnalyticsService.instance.examBookingOpen();
    await _openLink(AppConfig.wordUrl);
  }

  Future<void> _openLink(String url) =>
      _launch(Uri.parse(url), fallbackCopy: url);

  Future<void> _sendEmail(String address, {String? subject}) => _launch(
    Uri(
      scheme: 'mailto',
      path: address,
      // Encoded by hand: queryParameters would turn spaces into "+".
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    ),
    fallbackCopy: address,
  );

  Future<void> _launch(Uri uri, {required String fallbackCopy}) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      await _copy(fallbackCopy, message: 'Nie udało się otworzyć – skopiowano');
    }
  }

  Future<void> _copy(String value, {String message = 'Skopiowano'}) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$message: $value')));
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
              _step(
                '1',
                'Otwórz portal Info-Kierowca (przycisk na dole ekranu)',
              ),
              _step(
                '2',
                'Zaloguj się przez login.gov.pl lub aplikację eDO App',
              ),
              _step('3', 'Wybierz profil PKK i kategorię prawa jazdy (np. B)'),
              _step('4', 'Wybierz ośrodek: WORD Szczecin'),
              _step('5', 'Wybierz egzamin teoretyczny, praktyczny lub łączony'),
              _step('6', 'Wybierz datę i godzinę z wolnych terminów'),
              _step('7', 'Zatwierdź dane na podsumowaniu'),
              _step('8', 'Opłać egzamin – po opłacie rezerwacja jest gotowa'),
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
            title: 'Zamówienie blankietu po zdanym egzaminie (online)',
            children: [
              _step(
                '1',
                'Wykonaj przelew: $_licenceFee na rachunek Urzędu Miasta '
                    'Szczecin',
              ),
              _copyBox([
                _copyRow(
                  'Numer konta',
                  _licenceAccountDisplay,
                  copyValue: _licenceAccount,
                ),
                _copyRow('Tytuł przelewu', _licenceTransferTitle),
              ]),
              _step(
                '2',
                'Pobierz potwierdzenie przelewu w formacie PDF lub jako '
                    'zdjęcie',
              ),
              _step(
                '3',
                'Wyślij potwierdzenie e-mailem do urzędu, dołączając je '
                    'jako załącznik',
              ),
              _copyBox([
                _copyRow('Adres e-mail', _cityOfficeEmail),
                _copyRow('Temat wiadomości', _licenceEmailSubject),
                _copyRow(
                  'Załącznik',
                  'Potwierdzenie wykonania przelewu',
                  copyable: false,
                ),
              ]),
              _actionButton(
                icon: Icons.mail_outline_rounded,
                label: 'Napisz do urzędu',
                onPressed: () =>
                    _sendEmail(_cityOfficeEmail, subject: _licenceEmailSubject),
              ),
              const SizedBox(height: 12),
              _step(
                '4',
                'W ciągu 3–4 tygodni dostaniesz wiadomość, że blankiet jest '
                    'gotowy do odbioru',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.swap_horiz_rounded,
            iconColor: AppTheme.routeBlue,
            title: 'Egzamin w innym mieście – zwolnienie PKK',
            children: [
              _infoItem(
                'Jeśli chcesz zdawać egzamin w innym mieście, musisz złożyć '
                'wniosek o zwolnienie Profilu Kandydata na Kierowcę (PKK).',
              ),
              const SizedBox(height: 4),
              _step('1', 'Pobierz formularz wniosku o zwolnienie PKK'),
              _actionButton(
                icon: Icons.download_rounded,
                label: 'Pobierz formularz (PDF)',
                onPressed: () => _openLink(_pkkReleaseFormUrl),
              ),
              const SizedBox(height: 12),
              _step(
                '2',
                'Wypełnij wszystkie wymagane pola i upewnij się, że dane są '
                    'prawidłowe',
              ),
              _step(
                '3',
                'Wyślij skan wypełnionego formularza lub jego wersję '
                    'elektroniczną do WORD-u',
              ),
              _copyBox([_copyRow('Adres e-mail', _wordOfficeEmail)]),
              _actionButton(
                icon: Icons.mail_outline_rounded,
                label: 'Napisz do WORD Szczecin',
                onPressed: () => _sendEmail(_wordOfficeEmail),
              ),
              const SizedBox(height: 12),
              _step(
                '4',
                'PKK powinien zostać zwolniony w ciągu około 2 dni roboczych. '
                    'Potem możesz zadzwonić do WORD-u, aby potwierdzić '
                    'realizację wniosku',
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
                'Zarezerwuj egzamin online →',
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

  Widget _copyBox(List<Widget> rows) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 34, bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: rows),
    );
  }

  Widget _copyRow(
    String label,
    String value, {
    String? copyValue,
    bool copyable = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                SelectableText(
                  value,
                  style: GoogleFonts.poppins(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (copyable)
          IconButton(
            tooltip: 'Kopiuj: $label',
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(copyValue ?? value),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 34),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
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
