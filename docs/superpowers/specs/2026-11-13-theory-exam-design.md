# Egzamin Teoretyczny – projekt funkcji

Data: 2026-11-13 · Repozytorium: `drivio-2026-09-24` · Gałąź robocza: `feat/theory-exam` (powstanie po akceptacji)

## 1. Cel i powód

Nowa sekcja Drivio do nauki na egzamin teoretyczny na prawo jazdy kat. B. Korzysta z oficjalnych pytań Ministerstwa Infrastruktury, ma tryb losowego pytania i symulację pełnego egzaminu na zasadach WORD. Ma zatrzymać kursantów w aplikacji i zarabiać na reklamach. Sekcję trzeba odróżnić od istniejącej trasy `/exam`, czyli zapisu na egzamin w WORD, której nie zmieniamy.

**Cele**
- Wszystkie pytania kat. B, które nie mają filmu (1106 pytań, z czego 912 ze zdjęciem).
- Pełny egzamin zgodny z § 19 rozporządzenia MI z 24.11.2023 (Dz.U. 2023 poz. 2659).
- Brak kosztów serwera: pytania i zdjęcia są w aplikacji, postępy zapisuje telefon.
- Reklamy: mały baner i pełnoekranowy filmik co jakiś czas. Użytkownicy premium nie widzą reklam.

**Poza zakresem pierwszej wersji**
- Pytania z filmami i same filmy (decyzja użytkownika).
- Kategorie inne niż B.
- Tłumaczenia EN, DE i UA (baza je zawiera, więc można je dodać później).
- Nauka według tematów: baza nie ma kolumny z tematem, więc trzeba by ją oznaczyć ręcznie.
- Synchronizacja postępów w chmurze (Firestore).

**Czego unikamy**
- Reklamy w trakcie odliczania czasu na pytanie lub tuż przy przyciskach odpowiedzi.
- Udawania, że to jest pełna baza WORD. Ekran sekcji jasno mówi, że na prawdziwym egzaminie są też pytania z filmami.
- Zmian w obecnych ekranach poza dodaniem wejścia do sekcji.

## 2. Źródło pytań

- Plik `KATALOG_dla_kandydatów_na_kierowców_072026.xlsx` z gov.pl/web/infrastruktura/prawo-jazdy, aktualizacja 30.07.2026.
- Przydatne kolumny: Numer pytania, Pytanie, Odpowiedź A/B/C, Poprawna odp (T/N/A/B/C), Media, Zakres struktury, Liczba punktów, Kategorie.
- Zdjęcia pochodzą z `multimedia_do_pytan.zip` (9,5 GB, pobierane jednorazowo na komputer, nigdy do repozytorium) oraz z „Multimedia do pytań – cz. 2” (60 MB).
- Bez filmów zostaje: podstawowe (TAK/NIE) 289 × 3 pkt, 251 × 2 pkt, 181 × 1 pkt; specjalistyczne (A/B/C) 155 × 3 pkt, 151 × 2 pkt, 79 × 1 pkt. To wystarcza na losowanie pełnego egzaminu.

## 3. Podejścia (rozważone i wybrane)

| Podejście | Zalety | Wady |
|---|---|---|
| **A. Wszystko w aplikacji (wybrane)** | Zero kosztów przy każdej liczbie użytkowników, działa offline, najprostsze | Aplikacja większa o ok. 60–100 MB; każda zmiana bazy wymaga nowej wersji w App Store |
| B. Pytania w aplikacji, zdjęcia w Firebase Storage | Mniejsza aplikacja, bazę można podmienić bez wydania | Koszt około 30–150 USD miesięcznie przy 10 tys. aktywnych dziennie; potrzebny internet |
| C. Wszystko w Firestore | Edycja w panelu | Koszt odczytów rośnie z liczbą użytkowników; nie działa offline |

Wybór użytkownika: A.

## 4. Przygotowanie danych (jednorazowo, skrypt)

Skrypt w `tool/theory_exam/` (Dart CLI):
1. Wczytuje XLSX i zostawia tylko pytania kat. B, których media nie są plikiem `.wmv`.
2. Ujednolica dane: literówki w „Zakres struktury” (`Specajlistyczny` i podobne), wielkość liter, białe znaki; usuwa puste wiersze i 7 zdublowanych numerów (zostaje pierwsze wystąpienie, reszta trafia do raportu).
3. Dla każdego zdjęcia: szuka pliku w rozpakowanych paczkach, zmniejsza do najwyżej 1080 px szerokości i zapisuje jako WebP (jakość ok. 75) w `assets/theory_exam/img/<numer>.webp`.
4. Pytanie, któremu brakuje zdjęcia, jest pomijane i zapisane w raporcie.
5. Zapisuje `assets/theory_exam/questions_b.json` z polami `sourceVersion: "2026-07"` i `generatedAt`.
6. Wypisuje raport: liczby pytań w każdej grupie, pominięte pytania, łączny rozmiar zdjęć.

Gotowy JSON i zdjęcia trafiają do repozytorium; XLSX i ZIP nie.

## 5. Model danych

```dart
enum TheoryPart { basic, specialist }      // PODSTAWOWY / SPECJALISTYCZNY

class TheoryQuestion {
  final int id;               // „Numer pytania” z bazy MI
  final String text;
  final TheoryPart part;
  final int points;           // 1, 2 lub 3
  final List<String> answers; // basic: ['TAK','NIE']; specialist: [A, B, C]
  final int correctIndex;
  final String? image;        // ścieżka do pliku w assets albo null
}
```

Postępy zapisywane na telefonie (SharedPreferences, jeden klucz JSON, kilkadziesiąt KB):
- `QuestionStats` dla każdego `id`: liczba prób, liczba dobrych odpowiedzi, czy ostatnia odpowiedź była błędna, data ostatniej odpowiedzi.
- `ExamRecord`: data, wynik, zdany tak/nie, czas, lista `(id, wybrana odpowiedź)`. Trzymamy 30 ostatnich.
- Dostęp przez interfejs `TheoryProgressRepository`, żeby później można było dodać synchronizację w chmurze bez przepisywania ekranów.

Stan w Riverpod (`lib/providers/theory_exam_provider.dart`):
- `theoryQuestionBankProvider` (FutureProvider wczytujący JSON z assets),
- `theoryProgressProvider`,
- osobny notifier dla trwającego egzaminu i dla sesji nauki.

## 6. Tryby

1. **Losuj pytanie.** Pytania w losowej kolejności, bez końca. Po odpowiedzi od razu widać, czy była dobra, i podświetla się poprawna odpowiedź. Przycisk „Dalej”. Nie ma limitu czasu.
2. **Pełny egzamin (jak w WORD).**
   - 20 pytań podstawowych (10 × 3, 6 × 2, 4 × 1 pkt) i 12 specjalistycznych (6 × 3, 4 × 2, 2 × 1 pkt), losowanych bez powtórzeń.
   - Pytanie podstawowe: 20 s na zapoznanie się z treścią i zdjęciem, potem 15 s na odpowiedź. Odpowiedzieć można od razu, jak w WORD.
   - Pytanie specjalistyczne: łącznie 50 s.
   - Odpowiedź można zmieniać, dopóki nie przejdzie się dalej. Do poprzednich pytań nie da się wrócić. Brak odpowiedzi daje 0 pkt.
   - Cały egzamin ma limit 25 minut. Wynik: ile punktów z 74, zdaje się od 68.
   - Po egzaminie można przejrzeć wszystkie pytania z zaznaczeniem błędów.
   - Wyjście w trakcie wymaga potwierdzenia i egzamin przepada.
3. **Nauka.** Pytania po kolei, z filtrami: część (podstawowa lub specjalistyczna), punkty (3/2/1), „tylko nieprzerobione”. Odpowiedzi sprawdzane od razu, tak jak w trybie losowania. Aplikacja pamięta, gdzie użytkownik skończył.
4. **Powtórka błędów.** Pytania, na które ostatnio padła zła odpowiedź. Pytanie znika z listy po dobrej odpowiedzi. Gdy lista jest pusta, aplikacja pokazuje gratulacje.

Ekran główny sekcji pokazuje:
- postęp (ile pytań z 1106 już było, ile procent dobrych odpowiedzi),
- ostatni wynik egzaminu i serię zdanych egzaminów z rzędu,
- 4 kafelki trybów, przy powtórce błędów z liczbą pytań,
- informację o źródle: „Pytania: Ministerstwo Infrastruktury, stan 07.2026. Pytania z filmami nie są uwzględnione.”

## 7. Ekrany i nawigacja

Trasy w `lib/app.dart`, wszystkie opakowane w `_DarkOnly`, tak jak ekran `/exam`:

| Trasa | Ekran |
|---|---|
| `/theory` | `TheoryHomeScreen` |
| `/theory/random` | `TheoryPracticeScreen(mode: random)` |
| `/theory/learn` | `TheoryPracticeScreen(mode: learn)` + filtry |
| `/theory/mistakes` | `TheoryPracticeScreen(mode: mistakes)` |
| `/theory/exam` | `TheoryExamScreen` |
| `/theory/exam/result` | `TheoryExamResultScreen` (z przeglądem odpowiedzi) |

- Pliki w `lib/screens/theory_exam/`, a wspólne widżety (karta pytania, przyciski TAK/NIE i A/B/C, pasek czasu, zdjęcie z powiększaniem przez `photo_view`) w `lib/widgets/theory_exam/`.
- Wejście do sekcji: nowa pozycja „Egzamin teoretyczny” w szufladzie menu, w grupie „NAUKA I EGZAMIN” (`map_screen.dart`), oraz kafelek-skrót na ekranie `/exam`. Dolny pasek zostaje bez zmian.
- Wygląd zgodny z `AppTheme`: ciemne tło, czerwony `primary`, Poppins, zielony `successColor` dla dobrej odpowiedzi, czerwony dla złej.

Szkic pytania na egzaminie:
```
┌──────────────────────────────┐
│ Pytanie 7/32 · 3 pkt   ⏱ 0:12 │
│ ▓▓▓▓▓▓▓▓▓░░░░░ (pasek czasu)  │
│ [ zdjęcie, tap = powiększ ]   │
│ Czy w tej sytuacji masz...?   │
│   [   TAK   ]   [   NIE   ]   │
│              [ Dalej → ]      │
└──────────────────────────────┘
```

## 8. Reklamy

- **Baner:** istniejący `PremiumAwareBannerAd` na dole ekranu głównego sekcji, w trybach losowania, nauki i powtórki oraz na ekranie wyniku. Podczas pełnego egzaminu baneru nie ma.
- **Filmik pełnoekranowy (interstitial):**
  - nowa metoda `AdService.showInterstitial()` i stała `AppConfig.admobIosInterstitialId`;
  - w buildach debug testowe ID Google: `ca-app-pub-3940256099942544/4411468910`;
  - reklama ładuje się wcześniej, żeby nie było czekania.
- **Zasady wyświetlania** w czystej klasie `TheoryAdPolicy`, którą da się testować, ze stałymi w jednym miejscu:
  - po zakończeniu pełnego egzaminu, przed ekranem wyniku;
  - w trybach losowania, nauki i powtórki co 10 odpowiedzi;
  - co najmniej 3 minuty między filmikami;
  - pierwsze 2 minuty w sekcji bez filmiku;
  - nigdy w trakcie odliczania czasu.
- **Premium** nie widzi reklam; status sprawdzamy tak samo jak dla obecnego baneru.
- **Brak zgody, brak reklamy lub błąd:** aplikacja przechodzi dalej bez komunikatu.
- **Do zrobienia przez użytkownika:** utworzyć w AdMob jednostkę Interstitial dla iOS i podać jej ID przed wydaniem.

## 9. Darmowe i premium

Wszystkie tryby są darmowe, a premium wyłącza reklamy (spójnie z resztą aplikacji). To decyzja projektowa, nie decyzja użytkownika, i można ją zmienić.

## 10. Analityka

Nowe metody w `AnalyticsService`:
- `theoryModeOpen(mode)`,
- `theoryExamFinished(score, passed)`,
- `theoryInterstitialShown(trigger)`.

Pojedynczych odpowiedzi nie logujemy, żeby nie zalewać analityki zdarzeniami.

## 11. Testy

- **Skrypt danych:** wczytywanie przykładowego XLSX, poprawianie literówek, usuwanie duplikatów, odrzucanie pytań z filmami.
- **Integralność bazy** (test na prawdziwym `questions_b.json`):
  - liczby pytań w każdej grupie wystarczają na egzamin;
  - każde wskazane zdjęcie istnieje w assets;
  - `correctIndex` mieści się w zakresie;
  - brak duplikatów `id`.
- **Generator egzaminu:** zawsze 10/6/4 + 6/4/2, bez powtórzeń, przy ustalonym ziarnie losowania wynik jest powtarzalny.
- **Punktacja:** maksimum 74, próg 68, brak odpowiedzi daje 0.
- **Logika czasu** z udawanym zegarem: 20+15 s, 50 s, przejście dalej po upływie czasu, limit 25 min.
- **`TheoryAdPolicy`:** co 10 odpowiedzi, 3 min odstępu, 2 min na start, brak reklam dla premium.
- **`TheoryProgressRepository`:** zapis i odczyt, limit 30 egzaminów, wejście pytania do powtórki błędów i wyjście z niej.
- **Widżety:** odpowiadanie TAK/NIE i A/B/C, brak możliwości powrotu, ekran wyniku, pusta powtórka błędów.
- Obecne testy muszą dalej przechodzić (`flutter test`, `flutter analyze`).

## 12. Etapy wdrożenia (gałąź `feat/theory-exam`)

0. Utworzenie gałęzi z `release`. Pobranie paczek multimediów (9,5 GB i 60 MB) po zgodzie użytkownika, rozpakowanie poza repozytorium.
1. Skrypt danych i wygenerowanie `questions_b.json` z obrazami WebP. Raport z liczbami i rozmiarem.
2. Model, repozytorium postępów, generator egzaminu i punktacja (najpierw testy).
3. Ekran główny sekcji, wejście z menu i z `/exam`, tryb losowania.
4. Tryb nauki i powtórka błędów.
5. Pełny egzamin z odliczaniem czasu i ekran wyniku z przeglądem.
6. Reklamy (baner i filmik z `TheoryAdPolicy`) oraz analityka.
7. Szlifowanie: wygląd na małych ekranach, sprawdzenie rozmiaru aplikacji, uruchomienie na symulatorze iOS i zrzuty ekranu.
8. TestFlight. Wydanie w App Store dopiero po decyzji użytkownika (punkt 13).

## 13. Ryzyka i otwarte sprawy

- **Prawa do zdjęć.** Tekst pytań to prawdopodobnie materiał urzędowy, który nie jest chroniony prawem autorskim (art. 4 pkt 2 pr. aut.). Według interpelacji nr 16404 z kwietnia 2026 część multimediów należy jednak do podmiotów prywatnych. Przed wydaniem w App Store warto to potwierdzić, na przykład pismem do MI albo u prawnika. Decyzja należy do użytkownika.
- **Reforma bazy.** MI zapowiada mniejszą bazę i Centrum Egzaminowania, a projekt ustawy może ograniczyć jawność pytań. Pole `sourceVersion` i skrypt pozwalają szybko wygenerować bazę od nowa.
- **Rozmiar aplikacji** wzrośnie o ok. 60–100 MB (to szacunek do sprawdzenia w etapie 1). Jeśli wyjdzie za dużo, zdjęcia przeniesiemy do Firebase Storage, czyli podejście B.
- **Interstitial ID:** do czasu, aż użytkownik je poda, używamy testowego ID.

## 14. Do decyzji wykonawcy

Nazwy klas i plików, dokładny wygląd kart, animacje, sposób przechowywania stanu postępów (klucze JSON), jakość i rozmiar WebP w granicach jakości czytelnej na iPhonie.
