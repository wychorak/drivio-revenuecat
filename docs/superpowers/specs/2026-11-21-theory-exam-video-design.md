# Egzamin Teoretyczny – filmy i domknięcie modułu

Data: 2026-11-21 · Repozytorium: `drivio-2026-09-24` · Gałąź: `feat/theory-exam-video` (odbita od `feat/theory-exam`, PR #2)

## 1. Cel i powód

Użytkownik chce dokończyć cały moduł quizu: mają być wszystkie pytania kat. B z oficjalnej bazy, także te z filmami. Potwierdził, że może używać mediów z bazy gov.pl.

Dziś sekcja ma 1100 pytań, w tym 911 ze zdjęciem. Brakuje 1029 pytań z filmem, czyli prawie połowy pytań podstawowych na prawdziwym egzaminie. Bez nich pełny egzamin nie odpowiada temu w WORD.

**Cele**
- 2129 pytań kat. B: dotychczasowe 1100 plus 1029 z filmem. Nadal pomijamy 6 pytań z błędnymi danymi w katalogu.
- Filmy jako MP4 w Firebase Storage (decyzja użytkownika). Telefon pobiera każdy film raz i go zachowuje.
- Pełny egzamin losuje pytania z całej puli, także filmowe. Film odtwarza się tak jak w WORD.
- Egzamin bez internetu nadal jest możliwy (szczegóły w punkcie 4).

**Poza zakresem**
- Nauka według tematów (decyzja użytkownika: „nie teraz”).
- Kategorie inne niż B, tłumaczenia, synchronizacja postępów w chmurze.

**Czego unikamy**
- Przerywania egzaminu z powodu sieci. Wszystkie filmy egzaminu są na telefonie przed startem.
- Pobierania tego samego filmu kilka razy.
- Publicznego dostępu do plików: czytać mogą tylko zalogowani, a zapis jest wyłączony.

## 2. Audyt materiałów (2026-11-21)

Źródło nie zmieniło się: na gov.pl nadal jest katalog 07.2026, `multimedia_do_pytan.zip` (12.02.2026) i część 2 (19.10.2026).

| Sprawdzenie | Wynik |
|---|---|
| Pytania kat. B w katalogu | 2135 wierszy: 1029 z filmem (wszystkie podstawowe), 912 ze zdjęciem, 194 bez mediów |
| Unikalne pliki mediów kat. B | 1701: 921 `.wmv`, 780 `.jpg`/`.jpeg` (część plików służy kilku pytaniom) |
| Brakujące pliki | **0**: każde pytanie ma swój plik w paczkach |
| Pliki w obu paczkach naraz | 0, więc kolejność paczek nie ma znaczenia |
| Pliki niepowiązane z żadnym pytaniem | 16: próbki `egz_test`, robocze kopie (np. `gnw 12.jpg.jpg`). Pomijamy je. |
| Pytania bez mediów | 32 podstawowe i 162 specjalistyczne. To pytania ogólne (np. alkohol, pierwsza pomoc), na prawdziwym egzaminie też są bez mediów. |
| Błędne wiersze | 6: format odpowiedzi nie pasuje do części egzaminu. Pomijamy je, bez zmian. |
| Dopasowanie treści | Ręczna próbka 12 zdjęć i 4 filmów: wszystkie pasują do pytań, a oficjalne odpowiedzi zgadzają się z obrazem. |
| Filmy | 1024×576, 7–11 s, 6,94 GB w WMV. Po konwersji do H.264 (CRF 26) zostaje ok. 27%, czyli ok. **1,9 GB**. Niektóre mają dźwięk (WMA). |

## 3. Dane i hosting

- `tool/theory_exam/build_bank.py` dostaje opcję `--videos-out DIR`. Konwertuje każdy użyty WMV ffmpegiem:
  - H.264, szerokość ≤ 1024 px, CRF 26, `yuv420p`, `+faststart`;
  - dźwięk AAC mono 64 kb/s, jeśli film go ma, bo 21 pytań dotyczy sygnałów dźwiękowych.
- Nazwa pliku to `<sha1 źródła, 12 znaków>.mp4`. Ten sam film dla kilku pytań to jeden plik, a zmieniony film dostaje nową nazwę, więc stara kopia na telefonie nie zostanie pomylona z nową.
- Pytanie w JSON dostaje pola `"video": "theory_exam/videos/2026-07/<nazwa>.mp4"` i `"videoBytes"` (do paska postępu i licznika miejsca).
- Pliki trafiają do Firebase Storage projektu `drivio-a7d9c` pod `theory_exam/videos/2026-07/`.
- W `firebase/storage.rules` dochodzi reguła: `theory_exam/videos/{version}/{file}`: odczyt dla zalogowanych, zapis zabroniony. Do tego test w `firebase/rules-tests`.
- Reguły i pliki wysyłam dopiero po zgodzie użytkownika.
- **Koszt** (wybór użytkownika): miejsce ok. 1,9 GB, czyli kilka groszy miesięcznie. Płatny jest transfer powyżej darmowego limitu Firebase. Film ma średnio ok. 2 MB i każdy użytkownik pobiera go najwyżej raz.

## 4. Pobieranie filmów na telefon

Odpowiedź na pytanie użytkownika: film pobiera się **raz na telefon**, a nie przy każdym egzaminie.

- **Nauka:** film pobiera się przy pierwszym wyświetleniu pytania, a następny film jest pobierany z wyprzedzeniem.
- **Pełny egzamin:** przed startem ekran „Przygotowuję egzamin…” pobiera tylko te z wylosowanych filmów, których jeszcze nie ma na telefonie. To zwykle ok. 10 filmów, czyli ok. 20 MB, a z czasem coraz mniej. Pokazuje pasek postępu i ma przycisk „Spróbuj ponownie”.
- **Bez internetu przed egzaminem:** aplikacja proponuje „Egzamin bez filmów”, wylosowany z pytań, które działają offline. Wynik ma oznaczenie, że to wersja bez filmów.
- **Bez internetu w nauce:** pytania filmowe, których nie ma na telefonie, są pomijane z krótkim komunikatem.
- Pliki leżą w katalogu aplikacji (`Application Support/theory_videos`). Pobiera je `firebase_storage` (`writeToFile`), bo to zachowuje logowanie i App Check, których nie przekazałby zwykły adres URL.
- Ekran główny sekcji pokazuje „Pobrane filmy: X MB” i przycisk „Usuń pobrane filmy”. Gdy ktoś przejdzie całą bazę, filmy zajmą najwyżej ok. 1,9 GB.

## 5. Odtwarzanie i zasady czasu

- Nowa zależność `video_player`, odtwarzana z pliku lokalnego.
- **Pełny egzamin**, pytanie z filmem, zgodnie z przebiegiem w WORD:
  1. 20 s na zapoznanie się z pytaniem; przycisk „Start” skraca ten czas;
  2. film odtwarza się raz, bez przycisków i bez powtórki;
  3. po filmie zostaje ostatnia klatka i liczy się 15 s na odpowiedź.
- Odpowiedzieć można także w trakcie filmu. Łączny limit 25 min liczy się dalej.
- `ExamClock` dostaje fazę `video`. Długość filmu podaje odtwarzacz. Jeśli film nie ruszy w ciągu 3 s, odpowiedź zaczyna się od razu, żeby awaria odtwarzacza nie zjadała czasu.
- **Nauka:** film odtwarza się automatycznie, a przycisk „Odtwórz ponownie” pozwala obejrzeć go jeszcze raz.
- Obok filmów zostaje poprawka z poprzedniej wersji: wczytywanie z wyprzedzeniem zdjęcia do następnego pytania.

## 6. Reszta modułu

- Liczniki i opis źródła na ekranie głównym zmieniają się na 2129 pytań. Znika dopisek „Pytania z filmami nie są uwzględnione”.
- `bank_integrity_test` sprawdza, że każde pytanie z `video` ma `videoBytes` i nazwę pliku w formie `<hash>.mp4`. Zostają też dotychczasowe sprawdzenia.
- Reklamy działają bez zmian. Pełnoekranowa nigdy nie pojawia się w trakcie filmu, bo i tak nie ma jej w czasie odliczania.

## 7. Decyzje

| Decyzja | Kto |
|---|---|
| Hosting filmów w Firebase Storage | użytkownik |
| Nowa gałąź na bazie PR #2 | użytkownik |
| Bez nauki według tematów | użytkownik |
| Pobieranie przed egzaminem i egzamin bez filmów offline | propozycja, do potwierdzenia przy akceptacji planu |
| Zachowanie dźwięku, ścieżka i nazwy plików, próg 3 s dla awarii odtwarzacza | moje decyzje |
| Sposób wysyłki 1,9 GB do Storage (brak `gsutil`/`gcloud`) | do ustalenia przy wysyłce; zapytam przed instalacją narzędzi |
