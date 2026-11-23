# Baza pytań „Egzamin Teoretyczny”

`build_bank.py` tworzy z oficjalnych plików Ministerstwa Infrastruktury (https://www.gov.pl/web/infrastruktura/prawo-jazdy):
- `assets/theory_exam/questions_b.json`,
- zdjęcia `assets/theory_exam/img/<id>.webp`,
- z opcją `--videos-out` także filmy MP4 do Firebase Storage. Filmy nie trafiają do repozytorium ani do aplikacji.

Pliki źródłowe pobierz poza repozytorium. Nie wolno ich commitować:
- `KATALOG_dla_kandydatów_na_kierowców_072026.xlsx` (1,2 MB),
- `multimedia_do_pytan.zip` (9,5 GB),
- `Multimedia_do_pytań_-_cz_2_ver20261016.zip` (60 MB).

```bash
python -I tool/theory_exam/test_build_bank.py
python -I tool/theory_exam/build_bank.py --xlsx KATALOG.xlsx --zip multimedia_do_pytan.zip --zip multimedia_cz2.zip --out assets/theory_exam --videos-out FILMY
gcloud storage rsync FILMY gs://drivio-a7d9c.firebasestorage.app/theory_exam/videos/2026-07 --content-type=video/mp4 --cache-control="public, max-age=31536000, immutable"
```

Wymagany jest Pillow (`pip install Pillow`), a do filmów ffmpeg i ffprobe w `PATH`.

Filmy:
- format: H.264 CRF 26, szerokość do 1024 px, `+faststart`; dźwięk AAC mono, jeśli źródło go ma;
- nazwa pliku: `<sha1 źródła, 12 znaków>.mp4`, więc ponowne uruchomienie pomija gotowe pliki, a zmieniony film dostaje nową nazwę;
- wysyłka: `gcloud` (Google Cloud SDK) zalogowany kontem z dostępem do projektu;
- reguła odczytu jest w `firebase/storage.rules`. Dla nowej wersji katalogu zmień `SOURCE_VERSION` w skrypcie, tekst w `theorySourceNote` i wartość oczekiwaną w `test/theory_exam/bank_integrity_test.dart`.

Co skrypt pomija:
- pytania spoza kat. B,
- pytania z filmem (`.wmv`), gdy nie podano `--videos-out`,
- zdublowane numery pytań (zostaje pierwsze wystąpienie),
- wiersze, w których format odpowiedzi nie pasuje do części egzaminu. Przykład: pytanie oznaczone jako PODSTAWOWY ma odpowiedzi A/B/C. W katalogu 07.2026 dotyczy to 6 pytań kat. B: 3759, 3761, 4600, 7462, 13560, 13684,
- pytania, których pliku (zdjęcia albo filmu) brakuje w paczkach.

Kategorie do nauki:
- katalog nie ma kolumny z tematem, więc skrypt przypisuje kategorię (`topic`) według słów w treści pytania (`classify_topic`);
- odpowiedzi biorą udział tylko wtedy, gdy samo pytanie nie pasuje do żadnej reguły;
- reguły są sprawdzane po kolei i wygrywa pierwsza pasująca. Bez dopasowania pytanie trafia do `general` („Jazda – zasady ogólne”);
- w próbkach sprawdzonych ręcznie trafność wynosi ok. 90%.

Po zmianie reguł wystarczy przeliczyć same kategorie, bez paczek źródłowych:

```bash
python -I tool/theory_exam/build_bank.py --retag --out assets/theory_exam
```

Kategorie (23.11.2026):

| Kategoria | Pytania |
|---|---|
| Pierwszeństwo i skrzyżowania | 416 |
| Wyprzedzanie, wymijanie i pasy ruchu | 296 |
| Piesi, rowerzyści i hulajnogi | 217 |
| Prędkość i hamowanie | 184 |
| Zatrzymanie, parkowanie i manewry | 179 |
| Znaki i sygnały | 175 |
| Pojazd, dokumenty i kary | 147 |
| Jazda – zasady ogólne | 131 |
| Przejazdy kolejowe i tramwaje | 125 |
| Światła i warunki na drodze | 123 |
| Pierwsza pomoc i wypadki | 69 |
| Autostrady i drogi ekspresowe | 43 |
| Alkohol, leki i uwaga kierowcy | 24 |

## Ostatnie uruchomienie

21.11.2026, katalog 07.2026, z filmami (`--videos-out`, 4 wątki, ok. 1 h):
- 2129 pytań kat. B: 911 ze zdjęciem (45,7 MB WebP, w aplikacji), 1029 z filmem, reszta bez mediów;
- filmy: 921 plików MP4, razem 1520 MB, w Firebase Storage, nie w aplikacji. Wszystkie przeszły ffprobe (H.264), 225 ma dźwięk;
- grupy: podstawowe 1/2/3 pkt: 368/509/869, specjalistyczne 1/2/3 pkt: 78/150/155;
- pominięte: 6 z błędnym formatem (lista wyżej), 0 duplikatów, 0 brakujących mediów.

Wcześniej, 13.11.2026, bez filmów: 1100 pytań, w tym 911 ze zdjęciem.
