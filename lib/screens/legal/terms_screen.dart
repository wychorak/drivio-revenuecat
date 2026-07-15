import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Regulamin'),
        backgroundColor: AppTheme.bgDark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Regulamin aplikacji Drivio',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ostatnia aktualizacja: 1 marca 2026',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            '§1. Postanowienia ogólne',
            '''1. Niniejszy Regulamin określa zasady korzystania z aplikacji mobilnej Drivio (dalej: "Aplikacja"), dostępnej na platformach Android i iOS.

2. Właścicielem i operatorem Aplikacji jest firma Drivio (dalej: "Usługodawca").

3. Korzystanie z Aplikacji oznacza akceptację niniejszego Regulaminu w całości.

4. Usługodawca zastrzega sobie prawo do zmiany Regulaminu. O wszelkich zmianach użytkownicy zostaną poinformowani z co najmniej 14-dniowym wyprzedzeniem.

5. Aplikacja jest przeznaczona dla osób pełnoletnich lub za zgodą rodziców/opiekunów prawnych dla osób powyżej 16. roku życia.''',
          ),
          _section(
            '§2. Zakres usług',
            '''1. Aplikacja Drivio udostępnia:
   a) mapę "pułapek egzaminacyjnych" na terenie Szczecina i innych miast,
   b) bazę szkół nauki jazdy,
   c) informacje o rejestracji na egzamin na prawo jazdy,
   d) porady i wskazówki dla kandydatów na kierowców,
   e) system komentarzy i ocen.

2. Część funkcji Aplikacji jest dostępna wyłącznie dla użytkowników posiadających subskrypcję Premium.

3. Bezpłatni użytkownicy mogą przeglądać do ${5} pułapek dziennie.

4. Usługodawca nie gwarantuje ciągłości działania usług i zastrzega sobie prawo do czasowego wyłączenia Aplikacji w celach konserwacyjnych.''',
          ),
          _section(
            '§3. Rejestracja i konto użytkownika',
            '''1. Korzystanie z pełnych funkcji Aplikacji wymaga utworzenia konta użytkownika.

2. Użytkownik zobowiązuje się do podania prawdziwych danych podczas rejestracji.

3. Hasło do konta powinno być bezpieczne i nie może być udostępniane osobom trzecim.

4. Użytkownik ponosi pełną odpowiedzialność za działania podejmowane za pośrednictwem swojego konta.

5. Usługodawca ma prawo zablokować konto, jeżeli użytkownik narusza postanowienia Regulaminu.

6. Użytkownik może usunąć swoje konto w dowolnym momencie z poziomu ustawień Aplikacji.''',
          ),
          _section(
            '§4. Subskrypcja Premium',
            '''1. Aplikacja oferuje płatne plany subskrypcji Premium:
   a) Plan tygodniowy – 5,99 zł / 7 dni,
   b) Plan miesięczny – 20,99 zł / 30 dni,
   c) Plan roczny – 190,99 zł / rok.

2. Płatności w aplikacji mobilnej są realizowane przez Google Play lub App Store. Płatności Stripe mogą być używane wyłącznie w wersji webowej, jeśli jest dostępna.

3. Subskrypcja odnawia się automatycznie, chyba że użytkownik anuluje ją przed końcem okresu rozliczeniowego.

4. Anulowanie subskrypcji nie uprawnia do zwrotu środków za niewykorzystany okres, z wyjątkiem przypadków określonych w przepisach o prawach konsumenta.

5. Ceny podane są w złotych polskich i zawierają podatek VAT.''',
          ),
          _section(
            '§5. Treści użytkowników',
            '''1. Użytkownicy mogą dodawać treści do Aplikacji, w tym opisy pułapek egzaminacyjnych, zdjęcia, komentarze i opinie.

2. Dodając treści, użytkownik oświadcza, że posiada prawa do tych treści i udziela Usługodawcy nieodpłatnej licencji na ich wykorzystanie w ramach Aplikacji.

3. Zabrania się zamieszczania treści:
   a) naruszających prawa osób trzecich,
   b) zawierających wulgaryzmy i mowę nienawiści,
   c) będących reklamą lub spamem,
   d) niezgodnych z prawem,
   e) fałszywych lub wprowadzających w błąd.

4. Usługodawca zastrzega sobie prawo do usunięcia treści naruszających Regulamin bez uprzedniego powiadomienia użytkownika.

5. Usługodawca nie weryfikuje dokładności informacji dodawanych przez użytkowników.''',
          ),
          _section(
            '§6. Prawa autorskie i własność intelektualna',
            '''1. Wszelkie prawa do Aplikacji, w tym kodu źródłowego, szaty graficznej, logotypu i nazwy, należą do Usługodawcy.

2. Kopiowanie, modyfikowanie lub dystrybucja elementów Aplikacji bez zgody Usługodawcy jest zabroniona.

3. Usługodawca szanuje prawa autorskie osób trzecich. W przypadku naruszenia prosimy o kontakt.''',
          ),
          _section(
            '§7. Odpowiedzialność',
            '''1. Aplikacja dostarcza informacji o charakterze edukacyjnym i pomocniczym. Nie zastępuje oficjalnych materiałów egzaminacyjnych ani przepisów ruchu drogowego.

2. Usługodawca nie ponosi odpowiedzialności za:
   a) niedokładność lub aktualność informacji zawartych w Aplikacji,
   b) skutki korzystania z informacji dostarczanych przez Aplikację,
   c) działania osób trzecich korzystających z Aplikacji,
   d) przerwy w działaniu Aplikacji spowodowane czynnikami zewnętrznymi.

3. Usługodawca nie ponosi odpowiedzialności za wynik egzaminu na prawo jazdy użytkownika.''',
          ),
          _section(
            '§8. Ochrona danych osobowych',
            '''1. Zasady przetwarzania danych osobowych opisano w Polityce Prywatności, dostępnej w Aplikacji.

2. Korzystając z Aplikacji, użytkownik wyraża zgodę na przetwarzanie danych osobowych zgodnie z Polityką Prywatności.

3. Dane osobowe przetwarzane są zgodnie z RODO (Rozporządzenie Parlamentu Europejskiego i Rady (UE) 2016/679).''',
          ),
          _section(
            '§9. Reklamy i śledzenie',
            '''1. Aktualna wersja Aplikacji nie wyświetla reklam podmiotów trzecich.

2. Jeżeli reklamy zostaną wprowadzone w przyszłości, użytkownicy zostaną poinformowani o zasadach ich działania oraz wymaganych zgodach.

3. Nie używamy danych użytkownika do śledzenia reklamowego w aktualnej wersji Aplikacji.

4. Użytkownik może zarządzać uprawnieniami Aplikacji w ustawieniach urządzenia.''',
          ),
          _section(
            '§10. Postępowanie reklamacyjne',
            '''1. Reklamacje dotyczące działania Aplikacji należy kierować na adres: kontakt@drivio.app

2. Reklamacja powinna zawierać:
   a) dane kontaktowe użytkownika (email),
   b) opis problemu,
   c) datę wystąpienia problemu.

3. Usługodawca rozpatruje reklamacje w terminie 14 dni roboczych.

4. O wyniku rozpatrzenia reklamacji użytkownik zostanie poinformowany drogą elektroniczną.''',
          ),
          _section(
            '§11. Rozwiązanie umowy',
            '''1. Użytkownik może w każdej chwili zaprzestać korzystania z Aplikacji i usunąć konto.

2. Usługodawca może wypowiedzieć umowę z użytkownikiem z 30-dniowym wyprzedzeniem, bez podania przyczyny.

3. Usługodawca może natychmiastowo rozwiązać umowę, gdy użytkownik rażąco narusza Regulamin.''',
          ),
          _section(
            '§12. Postanowienia końcowe',
            '''1. W sprawach nieuregulowanych niniejszym Regulaminem zastosowanie mają przepisy prawa polskiego.

2. Wszelkie spory wynikające z korzystania z Aplikacji będą rozstrzygane przez właściwy sąd polski.

3. Jeżeli którekolwiek postanowienie Regulaminu okaże się nieważne, pozostałe postanowienia zachowują pełną moc obowiązującą.

4. Regulamin wchodzi w życie z dniem 1 marca 2026 roku.

Kontakt: kontakt@drivio.app
Drivio – Szczecin, Polska''',
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
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
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.dividerColor),
        const SizedBox(height: 12),
      ],
    );
  }
}
