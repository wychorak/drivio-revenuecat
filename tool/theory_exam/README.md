# Baza pytań „Egzamin Teoretyczny”

`build_bank.py` tworzy `assets/theory_exam/questions_b.json` i zdjęcia `assets/theory_exam/img/<id>.webp` z oficjalnych plików Ministerstwa Infrastruktury (https://www.gov.pl/web/infrastruktura/prawo-jazdy).

Pliki źródłowe pobierz poza repozytorium. Nie wolno ich commitować:
- `KATALOG_dla_kandydatów_na_kierowców_072026.xlsx` (1,2 MB),
- `multimedia_do_pytan.zip` (9,5 GB),
- `Multimedia_do_pytań_-_cz_2_ver20261016.zip` (60 MB).

```bash
python -I tool/theory_exam/test_build_bank.py
python -I tool/theory_exam/build_bank.py --xlsx KATALOG.xlsx --zip multimedia_do_pytan.zip --zip multimedia_cz2.zip --out assets/theory_exam
```

Wymagany jest Pillow (`pip install Pillow`). Dla nowej wersji katalogu zmień `SOURCE_VERSION` w skrypcie, tekst w `theorySourceNote` i wartość oczekiwaną w `test/theory_exam/bank_integrity_test.dart`.

Co skrypt pomija:
- pytania spoza kat. B,
- pytania z filmem (`.wmv`),
- zdublowane numery pytań (zostaje pierwsze wystąpienie),
- wiersze, w których format odpowiedzi nie pasuje do części egzaminu. Przykład: pytanie oznaczone jako PODSTAWOWY ma odpowiedzi A/B/C. W katalogu 07.2026 dotyczy to 6 pytań kat. B: 3759, 3761, 4600, 7462, 13560, 13684,
- pytania, których zdjęcia brakuje w paczkach.

## Ostatnie uruchomienie

13.11.2026, katalog 07.2026, czas ok. 2 min:
- 1100 pytań kat. B, w tym 911 ze zdjęciem (45,7 MB WebP),
- grupy: podstawowe 1/2/3 pkt: 181/250/286, specjalistyczne 1/2/3 pkt: 78/150/155,
- pominięte: 1029 pytań z filmem, 6 z błędnym formatem (lista wyżej), 0 duplikatów, 0 bez zdjęcia.
