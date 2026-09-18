# Drivio — bezpieczeństwo

Ostatni przegląd: 19 września 2026.

## Granice zaufania

Klient Flutter jest środowiskiem niezaufanym. Klucze Firebase, Google Maps,
AdMob i publiczne klucze SDK RevenueCat są identyfikatorami klienta i muszą być
ograniczone po stronie dostawcy. Prywatne klucze, konta serwisowe i sekret
webhooka nie mogą znaleźć się w aplikacji ani repozytorium.

Operacje uprzywilejowane wykonuje Firebase Admin SDK. Firestore i Storage
rozpoznają administratora wyłącznie po custom claimie `admin=true`. Lista
`ADMIN_EMAILS` służy do wskazania kont, którym chroniona funkcja backendowa może
nadać claim; sam adres e-mail nie daje dostępu do danych administratora.

## Zaimplementowane zabezpieczenia

- domyślna odmowa dostępu w regułach Firestore i Storage;
- kontrola właściciela, dozwolonych pól, typów i rozmiarów danych;
- blokada zapisu pól Premium przez klienta;
- Firebase App Check w aplikacji i enforcement dla wrażliwych funkcji callable;
- usuwanie konta po stronie backendu z kontrolą świeżości logowania;
- webhook RevenueCat chroniony sekretem nagłówka, odporny na duplikaty i stare zdarzenia;
- custom claim administratora nadawany wyłącznie przez Firebase Admin SDK;
- testy reguł oraz mapowania zdarzeń RevenueCat.

## Usuwanie konta

Funkcja `deleteAccount` usuwa komentarze, zgłoszenia i pułapki należące do
zalogowanego UID, pliki `traps/{uid}/`, dokument użytkownika i konto Firebase
Auth. Nie przyjmuje UID celu od klienta, wymaga poprawnego tokenu App Check oraz
logowania nie starszego niż pięć minut.

## Płatności

RevenueCat pozostaje źródłem prawdy dla mobilnego Premium. Firebase UID jest
używany jako RevenueCat App User ID, a webhook synchronizuje pola Premium do
Firestore jako serwerowy fallback. Id zdarzenia jest zapisywane, dzięki czemu
ponowiona dostawa nie wykonuje operacji drugi raz.

Bezpośrednie linki Stripe w wersji webowej wymagają osobnej, sprawdzonej
integracji płatności z RevenueCat i Firebase UID. Nie należy uznawać samego
otwarcia linku Stripe za aktywację Premium.

## Przed wdrożeniem

- ustawić sekrety backendu i wdrożyć Functions przed regułami wymagającymi claimu;
- zarejestrować token debug App Check dla emulatora, a potem sprawdzić tokeny produkcyjne;
- ograniczyć klucze klienta do właściwych aplikacji, pakietów i API;
- przetestować zakup, odnowienie, anulowanie, refund, lifetime i restore na urządzeniach;
- uzupełnić prawdziwe dane operatora w regulaminie i polityce prywatności;
- włączyć monitoring kosztów, błędów webhooka oraz nadużyć.
