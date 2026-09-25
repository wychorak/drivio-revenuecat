import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/services/ad_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Polityka prywatności'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Polityka Prywatności Drivio',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ostatnia aktualizacja: 19 września 2026',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            context,
            '1. Administrator danych',
            '''Administratorem danych jest operator aplikacji Drivio. Przed publiczną publikacją operator uzupełni pełną nazwę lub imię i nazwisko oraz adres wymagany przez prawo.

Kontakt z Administratorem:
Email: ${AppConfig.contactEmail}
Strona: www.drivio.app

W przypadku pytań dotyczących przetwarzania danych osobowych prosimy o kontakt pod powyższymi adresami.''',
          ),
          _section(
            context,
            '2. Jakie dane zbieramy',
            '''W zależności od sposobu korzystania z Aplikacji możemy zbierać następujące dane:

DANE PODAWANE BEZPOŚREDNIO:
• Adres email (przy rejestracji)
• Nazwa wyświetlana (przy rejestracji)
• Dane logowania obsługiwane przez Firebase Authentication; aplikacja nie ma dostępu do hasła
• Zdjęcia dodawane przez użytkownika
• Komentarze i opinie

DANE ZBIERANE AUTOMATYCZNIE:
• Adres IP
• Typ urządzenia i system operacyjny
• Wersja aplikacji
• Dane o lokalizacji (wyłącznie do wyświetlania mapy, za Twoją zgodą)
• Dane techniczne niezbędne do bezpieczeństwa i działania usług Firebase
• Dane o zakupach (identyfikatory transakcji)

DANE DOTYCZĄCE KONTA:
• Historia przeglądanych pułapek (liczby dzienne)
• Zapisane pułapki i szkoły
• Status subskrypcji Premium''',
          ),
          _section(
            context,
            '3. W jakim celu przetwarzamy dane',
            '''Twoje dane osobowe przetwarzamy w następujących celach:

a) ŚWIADCZENIE USŁUG (art. 6 ust. 1 lit. b RODO):
   – obsługa konta użytkownika,
   – realizacja subskrypcji Premium,
   – wyświetlanie spersonalizowanych treści.

b) UZASADNIONY INTERES (art. 6 ust. 1 lit. f RODO):
   – analiza i poprawa działania Aplikacji,
   – zapobieganie nadużyciom,
   – obsługa reklamacji.

c) ZGODA (art. 6 ust. 1 lit. a RODO):
   – dostęp do lokalizacji,
   – dostęp do aparatu lub biblioteki zdjęć, jeśli dodajesz zdjęcie.

d) OBOWIĄZEK PRAWNY (art. 6 ust. 1 lit. c RODO):
   – wystawianie faktur i rachunków,
   – przestrzeganie przepisów podatkowych.''',
          ),
          _section(
            context,
            '4. Komu udostępniamy dane',
            '''Twoje dane mogą być udostępniane następującym podmiotom:

DOSTAWCY USŁUG TECHNICZNYCH:
• Google LLC (Firebase) – hosting, baza danych, uwierzytelnianie
• Google Maps Platform – usługi mapowe
• Apple / Google – obsługa płatności w aplikacji mobilnej
• Stripe – obsługa płatności w wersji webowej, jeśli jest dostępna

ORGANY PUBLICZNE:
• Wyłącznie na podstawie przepisów prawa lub prawomocnego orzeczenia sądu.

Nie sprzedajemy Twoich danych osobowych podmiotom trzecim.

Dane mogą być przekazywane do państw trzecich (USA) na podstawie standardowych klauzul umownych zatwierdzonych przez Komisję Europejską.''',
          ),
          _section(
            context,
            '5. Jak długo przechowujemy dane',
            '''• Dane konta i treści użytkownika: przez okres korzystania z Aplikacji, a następnie usuwane w procesie usunięcia konta
• Dane o zakupach: zgodnie z obowiązkami prawnymi i okresami dostawców płatności; aplikacja przechowuje wyłącznie niezbędne informacje o uprawnieniu
• Logi techniczne: zgodnie z okresami skonfigurowanymi u dostawców infrastruktury
• Treści usunięte wcześniej przez użytkownika lub administratora: do zakończenia operacji usunięcia i kopii bezpieczeństwa dostawcy

Po upływie powyższych terminów dane są trwale usuwane lub anonimizowane.''',
          ),
          _section(
            context,
            '6. Twoje prawa',
            '''Na podstawie RODO przysługują Ci następujące prawa:

• DOSTĘP – możesz zażądać kopii swoich danych
• SPROSTOWANIE – możesz poprawić nieprawidłowe dane
• USUNIĘCIE ("prawo do bycia zapomnianym") – możesz zażądać usunięcia danych
• OGRANICZENIE PRZETWARZANIA – możesz ograniczyć przetwarzanie w określonych przypadkach
• PRZENOSZENIE – możesz otrzymać swoje dane w formacie JSON
• SPRZECIW – możesz sprzeciwić się przetwarzaniu opartemu na uzasadnionym interesie
• COFNIĘCIE ZGODY – w każdej chwili możesz cofnąć wyrażoną zgodę

Aby skorzystać ze swoich praw, skontaktuj się z nami: ${AppConfig.contactEmail}

Masz również prawo wniesienia skargi do Urzędu Ochrony Danych Osobowych (UODO).''',
          ),
          _section(
            context,
            '7. Bezpieczeństwo danych',
            '''Stosujemy następujące środki bezpieczeństwa:

• Szyfrowanie danych w transmisji (HTTPS/TLS)
• Obsługa danych uwierzytelniających przez Firebase Authentication
• Bezpieczna infrastruktura Firebase (Google Cloud)
• Regularne aktualizacje zabezpieczeń
• Dostęp do danych wyłącznie dla upoważnionych pracowników
• Monitoring i alerty bezpieczeństwa

W przypadku naruszenia bezpieczeństwa danych poinformujemy Cię i właściwe organy zgodnie z wymogami RODO.''',
          ),
          _section(
            context,
            '8. Pliki cookie i śledzenie',
            '''Aplikacja mobilna nie używa plików cookie. Jednak stosujemy podobne technologie:

• Firebase – logowanie, baza danych, przechowywanie zdjęć i dane techniczne potrzebne do działania Aplikacji
• Google Maps – wyświetlanie mapy i lokalizacji na mapie
• Lokalne preferencje urządzenia – zapamiętanie wybranego miasta

Wersja webowa Aplikacji może używać plików cookie niezbędnych do funkcjonowania.''',
          ),
          _section(
            context,
            '9. Reklamy w wersji bezpłatnej',
            '''W bezpłatnej wersji Drivio wyświetlamy dyskretny baner Google AdMob. Po wykorzystaniu darmowej odsłony pułapki użytkownik może dobrowolnie obejrzeć reklamę pełnoekranową z nagrodą; każda obejrzana reklama odblokowuje jedną dodatkową odsłonę, maksymalnie dwie dziennie. Użytkownicy Drivio Pro nie widzą reklam.

Przed załadowaniem reklamy Google User Messaging Platform sprawdza wymagane zgody. Drivio żąda wyłącznie reklam niepersonalizowanych, które nie są dobierane na podstawie wcześniejszej aktywności użytkownika. Google może przetwarzać dane techniczne urządzenia, adres IP oraz dane o wyświetleniu reklamy w celu dostarczenia reklamy, pomiaru i zapobiegania nadużyciom. Potwierdzenie nagrody jest sprawdzane przez Firebase na podstawie identyfikatora użytkownika i podpisanego zdarzenia AdMob.''',
          ),
          FutureBuilder<bool>(
            future: AdService.instance.isPrivacyOptionsRequired(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OutlinedButton.icon(
                  onPressed: AdService.instance.showPrivacyOptions,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Ustawienia prywatności reklam'),
                ),
              );
            },
          ),
          _section(
            context,
            '10. Zmiany polityki prywatności',
            '''1. Zastrzegamy sobie prawo do zmiany niniejszej Polityki Prywatności.

2. O istotnych zmianach poinformujemy Cię z co najmniej 14-dniowym wyprzedzeniem przez:
   – komunikat w Aplikacji,
   – wiadomość email, jeżeli kanał ten będzie dostępny.

3. Dalsze korzystanie z Aplikacji po wejściu w życie zmian oznacza ich akceptację.

4. Niniejsza Polityka Prywatności wchodzi w życie z dniem 1 marca 2026 roku.

Kontakt: ${AppConfig.contactEmail}
Drivio – Szczecin, Polska''',
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppTheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 20),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 12),
      ],
    );
  }
}
