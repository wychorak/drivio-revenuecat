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

## Ostatnie uruchomienie

13.11.2026, katalog 07.2026, czas ok. 2 min:
- 1100 pytań kat. B, w tym 911 ze zdjęciem (45,7 MB WebP),
- grupy: podstawowe 1/2/3 pkt: 181/250/286, specjalistyczne 1/2/3 pkt: 78/150/155,
- pominięte: 1029 pytań z filmem, 6 z błędnym formatem (lista wyżej), 0 duplikatów, 0 bez zdjęcia.
