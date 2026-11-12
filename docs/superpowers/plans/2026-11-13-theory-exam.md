# Egzamin Teoretyczny – plan implementacji

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Cel:** Sekcja quizu z oficjalnymi pytaniami kat. B bez filmów: losowanie, nauka, powtórka błędów i pełny egzamin jak w WORD. Pytania i zdjęcia są w aplikacji, a reklamy zarabiają.

**Architektura:** Pytania przygotowuje jednorazowo skrypt Pythona z XLSX i ZIP-ów MI do `assets/theory_exam/` (JSON + WebP). Logika w Dart nie zależy od Fluttera: bank pytań, generator egzaminu, punktacja, zegar egzaminu i zasady reklam. Postępy trzyma SharedPreferences za interfejsem repozytorium. Ekrany korzystają z Riverpod i GoRouter.

**Technologie:** Flutter 3 / Dart 3.11, flutter_riverpod 2, go_router 14, shared_preferences, google_mobile_ads 9, photo_view; Python 3.12 + Pillow (tylko skrypt danych).

**Spec:** `docs/superpowers/specs/2026-11-13-theory-exam-design.md`

**Odstępstwo od specu (decyzja wykonawcy):** skrypt danych jest w Pythonie zamiast w Dart CLI, bo pakiet `image` w Dart nie zapisuje WebP, a Pillow tak. Plik leży w `tool/theory_exam/`, tak jak w specu.

## Ograniczenia globalne

- Tylko kat. B. Pomijamy pytania z mediami `.wmv`.
- Pełny egzamin: podstawowe 10×3, 6×2, 4×1; specjalistyczne 6×3, 4×2, 2×1; maksymalnie 74 pkt, zdane przy ≥ 68.
- Czas: podstawowe 20 s na zapoznanie + 15 s na odpowiedź; specjalistyczne 50 s; cały egzamin 25 min. Bez powrotu do pytań, brak odpowiedzi = 0 pkt.
- Reklamy: filmik co 10 odpowiedzi, odstęp ≥ 3 min, pierwsze 2 min bez filmiku, po egzaminie przed wynikiem; nigdy w trakcie odliczania. Bez baneru na ekranie pełnego egzaminu. Premium nie widzi reklam.
- Testowe ID interstitial w debug: `ca-app-pub-3940256099942544/4411468910`.
- Teksty w UI po polsku. Ekrany opakowane w `_DarkOnly`. Kolory z `AppTheme`.
- Tekst o źródle: „Pytania: Ministerstwo Infrastruktury, stan 07.2026. Pytania z filmami nie są uwzględnione.”
- Historia egzaminów: maksymalnie 30 ostatnich.
- Nic poza `.env` nie trafia do repozytorium z plików MI (żadnego XLSX ani ZIP).

## Na co zwrócić uwagę przy przeglądzie

1. Aplikacja zamknięta w trakcie egzaminu: niedokończony egzamin nie trafia do historii i nie psuje statystyk (test w zadaniu 4).
2. Uszkodzony lub stary JSON postępów w SharedPreferences: aplikacja startuje z pustymi postępami zamiast się wysypać (test w zadaniu 2).
3. Upływ czasu w tle: telefon zablokowany w trakcie egzaminu. Po powrocie zegar liczy według rzeczywistego czasu (`DateTime`), a nie liczby ticków (test w zadaniu 3 z udawanym zegarem).
4. Powtórka błędów lub filtr nauki, które nie zwracają pytań: ekran pokazuje stan pusty zamiast błędu (test widżetu w zadaniu 5).
5. Brak reklamy lub zgody: przejście do wyniku nie czeka dłużej niż 5 s (test w zadaniu 7 z udawanym serwisem reklam).

---

### Zadanie 1: Skrypt danych i assets

**Pliki:**
- Utwórz: `tool/theory_exam/build_bank.py`, `tool/theory_exam/test_build_bank.py`, `tool/theory_exam/README.md`
- Wygeneruj: `assets/theory_exam/questions_b.json`, `assets/theory_exam/img/<id>.webp`
- Zmień: `pubspec.yaml` (assets: `assets/theory_exam/`, `assets/theory_exam/img/`)

**Interfejsy:**
- Tworzy JSON: `{"sourceVersion":"2026-07","generatedAt":ISO,"questions":[{"id":int,"text":str,"part":"basic"|"specialist","points":1|2|3,"answers":[str],"correct":int,"image":str|null}]}`. Dla `basic` `answers` = `["TAK","NIE"]`, a `correct` 0 = TAK. `image` to ścieżka assetu, np. `assets/theory_exam/img/123.webp`.

- [ ] Testy (unittest): `normalize_part('Specajlistyczny ')=='specialist'`, `normalize_part('PODSTAWOWY')=='basic'`; `is_category_b('A,B,C')` True, `'B1'` False; wiersz z `.wmv` odrzucony; duplikat `id` zostaje tylko raz; `correct` 'T'→0, 'N'→1, 'B'→1.
- [ ] Uruchom: `python -I tool/theory_exam/test_build_bank.py`. Oczekiwane: FAIL (brak modułu).
- [ ] Zaimplementuj `build_bank.py` z argumentami `--xlsx PATH --zip PATH [--zip PATH] --out assets/theory_exam`. XLSX czytamy przez `zipfile` i `xml`. Zdjęcia wybieramy z ZIP po nazwie pliku (bez rozróżniania wielkości liter, w dowolnym podfolderze), skalujemy do szerokości ≤ 1080 i zapisujemy jako WebP q=75. Pytania bez znalezionego zdjęcia pomijamy. Na koniec raport na stdout.
- [ ] Testy przechodzą. Uruchom na prawdziwych plikach i zapisz raport w README.
- [ ] Commit.

### Zadanie 2: Model, bank pytań i repozytorium postępów

**Pliki:**
- Utwórz: `lib/features/theory_exam/models.dart`, `question_bank.dart`, `progress_repository.dart`
- Testy: `test/theory_exam/question_bank_test.dart`, `test/theory_exam/progress_repository_test.dart`, `test/theory_exam/bank_integrity_test.dart`

**Interfejsy (tworzy):**
- `enum TheoryPart { basic, specialist }`
- `class TheoryQuestion { int id; String text; TheoryPart part; int points; List<String> answers; int correctIndex; String? image; factory fromJson(Map) }`
- `class QuestionBank { List<TheoryQuestion> questions; String sourceVersion; TheoryQuestion byId(int); static QuestionBank fromJsonString(String); static Future<QuestionBank> load(AssetBundle) }`
- `class QuestionStats { int attempts; int correct; bool lastWrong; DateTime? lastAnswered }`
- `class ExamRecord { DateTime date; int score; bool passed; Duration duration; List<(int id, int? answer)> answers }`
- `class TheoryProgress { Map<int,QuestionStats> stats; List<ExamRecord> exams; int learnCursor; Set<int> get mistakes; int get seenCount; double get accuracy }`
- `abstract class TheoryProgressRepository { Future<TheoryProgress> load(); Future<void> save(TheoryProgress) }`. Implementacja `SharedPrefsTheoryProgressRepository` pod kluczem `theoryExam.progress.v1`.
- `TheoryProgress recordAnswer(int id, bool correct, DateTime at)` oraz `TheoryProgress addExam(ExamRecord)`. Obie metody są niemutowalne i przycinają historię do 30.

- [ ] Testy: parsowanie przykładowego JSON; po `recordAnswer(5,false)` `mistakes=={5}`, po kolejnym `recordAnswer(5,true)` `mistakes` jest puste; `addExam` ×31 daje 30, najnowszy pierwszy; zapis i odczyt przez `SharedPreferences.setMockInitialValues`; niepoprawny JSON pod kluczem daje pusty `TheoryProgress`. Test integralności na prawdziwym assecie: brak duplikatów id, `correctIndex < answers.length`, każdy `image` istnieje na dysku, w każdej grupie (część × punkty) liczba pytań ≥ zapotrzebowania egzaminu.
- [ ] Testy padają. Zaimplementuj. Testy przechodzą: `flutter test test/theory_exam`.
- [ ] Commit.

### Zadanie 3: Generator egzaminu, punktacja i zegar

**Pliki:** utwórz `lib/features/theory_exam/exam_engine.dart`, test `test/theory_exam/exam_engine_test.dart`

**Interfejsy (tworzy):**
- `const examBlueprint = {TheoryPart.basic: {3:10, 2:6, 1:4}, TheoryPart.specialist: {3:6, 2:4, 1:2}}`, `const examMaxScore = 74`, `const examPassScore = 68`, `const examTotalLimit = Duration(minutes: 25)`.
- `List<TheoryQuestion> generateExam(QuestionBank bank, Random rng)` zwraca 32 pytania: najpierw 20 podstawowych, potem 12 specjalistycznych, w obu częściach w losowej kolejności.
- `int scoreExam(List<TheoryQuestion> qs, List<int?> answers)`.
- `enum QuestionPhase { reading, answering, done }`
- `class ExamClock { ExamClock({required DateTime Function() now}); void startQuestion(TheoryQuestion q); QuestionPhase get phase; Duration get remainingInPhase; Duration get remainingTotal; bool get timeUp; void skipReading(); }`. Podstawowe: faza reading 20 s, potem answering 15 s. Specjalistyczne: od razu answering 50 s. `timeUp` = koniec fazy answering albo 25 min łącznie. Wszystko liczone z `now()`.

- [ ] Testy: rozkład 10/6/4 + 6/4/2 i brak duplikatów (100 losowań z seedami); suma maksymalna 74; 68 → zdane, 67 → niezdane; brak odpowiedzi = 0; zegar z udawanym `now`: podstawowe po 20 s przechodzi w answering, po 35 s `timeUp`; `skipReading` od razu daje answering 15 s; specjalistyczne po 50 s `timeUp`; skok czasu o 10 min w tle daje poprawny `remainingTotal`.
- [ ] Testy padają, implementacja, testy przechodzą. Commit.

### Zadanie 4: Stan w Riverpod

**Pliki:** utwórz `lib/providers/theory_exam_provider.dart`, test `test/theory_exam/theory_providers_test.dart`

**Interfejsy (tworzy):**
- `final theoryQuestionBankProvider = FutureProvider<QuestionBank>`
- `final theoryProgressRepositoryProvider = Provider<TheoryProgressRepository>`
- `final theoryProgressProvider = AsyncNotifierProvider<TheoryProgressNotifier, TheoryProgress>` z metodami `Future<void> recordAnswer(int id, bool correct)`, `Future<void> addExam(ExamRecord r)`, `Future<void> setLearnCursor(int i)`
- `enum PracticeMode { random, learn, mistakes }`
- `class PracticeFilter { TheoryPart? part; int? points; bool onlyUnseen }`
- `List<TheoryQuestion> practiceQueue(QuestionBank b, TheoryProgress p, PracticeMode m, PracticeFilter f, Random rng)`: `random` daje wszystkie pytania przetasowane; `learn` daje pytania po filtrze, posortowane po id; `mistakes` daje pytania z `p.mistakes`.

- [ ] Testy: `practiceQueue` dla każdego trybu i filtra; `mistakes` przy pustych błędach daje pustą listę; egzamin nie jest zapisywany, dopóki nie zostanie wywołane `addExam` (przerwany egzamin nie zostawia śladu).
- [ ] Testy padają, implementacja, testy przechodzą. Commit.

### Zadanie 5: Ekran główny i ekran ćwiczeń

**Pliki:**
- Utwórz: `lib/screens/theory_exam/theory_home_screen.dart`, `theory_practice_screen.dart`, `lib/widgets/theory_exam/question_card.dart` (zdjęcie + tekst, tap otwiera `PhotoView`), `answer_buttons.dart` (`TAK/NIE` albo `A/B/C`, stan: nic / wybrana / dobra / zła)
- Zmień: `lib/app.dart` (trasy `/theory`, `/theory/random`, `/theory/learn`, `/theory/mistakes` w `_DarkOnly`)
- Test: `test/theory_exam/practice_screen_test.dart`

**Interfejsy:**
- `TheoryPracticeScreen({required PracticeMode mode})`. Po odpowiedzi woła `theoryProgressProvider.recordAnswer` i `TheoryAdController.onAnswer()` (zadanie 7; do tego czasu sama metoda bez działania).
- `QuestionCard({required TheoryQuestion question})`, `AnswerButtons({required TheoryQuestion question, int? selected, bool reveal, ValueChanged<int>? onSelect})`.

- [ ] Testy widżetów (bank i repozytorium nadpisane w ProviderScope): w trybie losowania tap „TAK” w złym pytaniu podświetla na czerwono, „NIE” na zielono, potem przycisk „Dalej” pokazuje następne pytanie; powtórka błędów bez błędów pokazuje „Brak błędów do powtórki”; ekran główny pokazuje liczbę przerobionych pytań i tekst o źródle.
- [ ] Testy padają, implementacja, testy przechodzą. Nauka: filtry w bottom sheet (część, punkty, tylko nowe) i pamiętanie miejsca przez `setLearnCursor`. Commit.

### Zadanie 6: Pełny egzamin i wynik

**Pliki:** utwórz `lib/screens/theory_exam/theory_exam_screen.dart`, `theory_exam_result_screen.dart`; zmień `lib/app.dart` (`/theory/exam`, `/theory/exam/result` z `extra: ExamRecord`); test `test/theory_exam/exam_screen_test.dart`

**Interfejsy:** zużywa `generateExam`, `ExamClock`, `scoreExam`, `addExam`. Ticker co 250 ms przez `Timer.periodic`, a `now` wstrzykiwalny przez `theoryClockProvider = Provider<DateTime Function()>`.

- [ ] Testy widżetów z udawanym zegarem: brak przycisku wstecz w pytaniach; po upływie 35 s pytanie podstawowe przechodzi samo, z 0 pkt; „Dalej” zatwierdza odpowiedź; po 32 pytaniach ekran wyniku pokazuje „X / 74” i „Zdany” lub „Niezdany”; wyjście (wstecz w AppBarze) pokazuje dialog i po potwierdzeniu nie zapisuje egzaminu; w przeglądzie wyniku widać złe odpowiedzi.
- [ ] Testy padają, implementacja, testy przechodzą. Commit.

### Zadanie 7: Reklamy, analityka i wejścia

**Pliki:**
- Utwórz: `lib/features/theory_exam/ad_policy.dart`, `lib/providers/theory_ad_provider.dart`
- Zmień: `lib/services/ad_service.dart` (`Future<void> preloadInterstitial()`, `Future<bool> showInterstitial({Duration timeout = const Duration(seconds: 5)})`), `lib/config/app_config.dart` (`admobIosInterstitialId`, na razie pusty string, wtedy w release reklamy nie ma), `lib/services/analytics_service.dart` (`theoryModeOpen`, `theoryExamFinished`, `theoryInterstitialShown`), `lib/screens/map/map_screen.dart` (pozycja w szufladzie w „NAUKA I EGZAMIN”: ikona `Icons.quiz_outlined`, „Egzamin teoretyczny”), `lib/screens/exam/exam_registration_screen.dart` (kafelek-skrót do `/theory`), baner `PremiumAwareBannerAd` na ekranach z zadania 5 i na wyniku
- Testy: `test/theory_exam/ad_policy_test.dart`, rozszerzenie testów ekranów

**Interfejsy:**
- `class TheoryAdPolicy { TheoryAdPolicy({required DateTime sectionEnteredAt, this.answersBetween = 10, this.minGap = const Duration(minutes: 3), this.warmup = const Duration(minutes: 2)}); bool onAnswer(DateTime now, {required bool premium}); bool onExamFinished(DateTime now, {required bool premium}); void markShown(DateTime now); }`
- `TheoryAdController` (Riverpod Notifier) łączy politykę z `AdService` i `isPremiumProvider`.

- [ ] Testy polityki: 10. odpowiedź po rozgrzewce daje true; 9. daje false; w ciągu 2 min od wejścia false; < 3 min od ostatniej reklamy false; premium zawsze false; `onExamFinished` po rozgrzewce true. Ekran egzaminu: przejście do wyniku z udawanym `showInterstitial`, który nigdy się nie kończy, następuje po ≤ 5 s.
- [ ] Testy padają, implementacja, testy przechodzą. Commit.

### Zadanie 8: Weryfikacja końcowa

- [ ] `flutter analyze`: 0 problemów; `flutter test`: wszystko zielone.
- [ ] Uruchomienie podglądu (web lub Windows, AdMob tam wyłączony): przejście przez tryby i egzamin, zrzuty ekranu.
- [ ] Rozmiar `assets/theory_exam` zapisany w README skryptu. Commit.
