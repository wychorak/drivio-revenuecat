# Drivio — release readiness (25 września 2026)

## Gotowe w kodzie

- iOS używa Bundle ID `com.drivio.com`, a App Store Connect ID to `6776345734`.
- Codemagic importuje grupę zmiennych `drivio secrets`, waliduje Firebase, Maps, admina i kontakt oraz przekazuje wartości przez `--dart-define`.
- Logowanie Apple używa Firebase Auth, aplikacja ma capability `Sign in with Apple`, a dokument użytkownika powstaje również po tym logowaniu.
- RevenueCat używa offeringu `driviooffers`, entitlementu `drivio pro relase` i produktów `drivioweek`, `driviomonth`, `driviolifetime`.
- Oba klucze Apple w RevenueCat mają status `Valid credentials`, webhook Firebase odpowiada `200`, a Apple Server Notifications są ustawione dla produkcji i sandboxa w App Store Connect.
- Functions `deleteAccount`, `refreshAdminClaim`, `revenueCatWebhook`, `getTrapViewStatus`, `consumeDailyTrapView` i `admobRewardSsv` są wdrożone na Node.js 22 w `europe-west1`; sekret webhooka RevenueCat pozostaje w Secret Manager.
- Zakup jest uznany za udany dopiero po aktywacji entitlementu. Jest restore, identyfikacja Firebase UID i ceny ze StoreKit.
- Paywall zawiera informację o odnowieniu, zakupie lifetime, regulaminie i polityce prywatności.
- AdMob iOS używa aplikacji `ca-app-pub-8263324816746737~5489467107`, banera `ca-app-pub-8263324816746737/9237140422` i jednostki rewarded interstitial `ca-app-pub-8263324816746737/8516770878`.
- Baner jest kompaktowy. Reklama z nagrodą jest dobrowolna, ma ekran wprowadzający z opcją pominięcia i służy tylko do odblokowania trzeciej pułapki. Brak reklam przy starcie; Drivio Pro nie ładuje reklam.
- Debug build używa testowego ID Google. Produkcja żąda reklam niepersonalizowanych i przechodzi przez UMP przed pierwszym żądaniem.
- Firebase App Check jest aktywowany w aplikacji: App Attest z fallbackiem DeviceCheck na iOS, Play Integrity na Androidzie i provider debug w debug buildzie.
- Firestore i Storage mają reguły default-deny, walidację pól, ownership, limity list/uploadu i custom claim `admin`.
- Limit pułapek: 1 darmowa odsłona i 2 kolejne, każda po podpisanym potwierdzeniu reklamy z nagrodą, na dzień kalendarzowy w strefie `Europe/Warsaw`. Transakcje i reset są po stronie Functions; klient nie może sam dopisać nagrody.
- Reguły backendu uznają administratora wyłącznie po custom claimie `admin=true`; `ADMIN_EMAILS` służy tylko chronionej funkcji nadającej claim i filtrowaniu UI.
- Admin ma kolejkę zgłoszeń i może odrzucić zgłoszenie lub usunąć zgłoszoną treść.
- Chroniona przez App Check funkcja usuwa własne komentarze, zgłoszenia, pułapki, zdjęcia, dokument użytkownika i konto Firebase. Na iOS konto połączone z Apple wymaga ponownej autoryzacji, a aplikacja cofa token Apple przed usunięciem. Ekran ostrzega, że usunięcie konta nie anuluje subskrypcji Apple.
- Nowe logo Drivio jest w ikonach iOS i Androida oraz w głównych miejscach interfejsu. Ikony macOS, Windows i web nie były częścią tej podmiany.
- Polityka prywatności, manifest prywatności i regulamin opisują AdMob oraz brak reklamy behawioralnej.

## Blokery w panelach — wykonać przed TestFlight

1. **Codemagic:** grupa musi nazywać się dokładnie `drivio secrets`. Na załączonym ekranie widać Maps/admin/kontakt, ale build wymaga też `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` i `FIREBASE_STORAGE_BUCKET`.
2. **App Check:** zarejestrować `com.drivio.com` w Firebase App Check, najpierw obserwować metryki TestFlight, a potem włączyć enforcement dla Firestore, Storage i Authentication. Nie włączać enforcement przed pierwszym poprawnym tokenem z TestFlight.
3. **Apple login — provider włączony, konfiguracja do potwierdzenia:** zrzut z 25.09 pokazuje `Enabled` w Firebase Authentication, ale nie pokazuje zapisanych pól. Otworzyć provider Apple i sprawdzić, czy **Services ID jest identyfikatorem utworzonym w Apple Developer**, a nie adresem e-mail `noreply@...`; czy Team ID, Key ID i prywatny klucz Sign in with Apple należą do tego samego zespołu i klucza; oraz czy sekcja OAuth code flow jest kompletna. W Apple Developer Services ID musi być powiązany z App ID `com.drivio.com`, domeną `drivio-a7d9c.firebaseapp.com` i Return URL `https://drivio-a7d9c.firebaseapp.com/__/auth/handler`. Adres `noreply@drivio-a7d9c.firebaseapp.com` należy tylko do konfiguracji Apple Private Email Relay. Nie umieszczać prywatnego klucza w repozytorium ani na zrzutach ekranu; klucz pokazany wcześniej na zrzucie należy wymienić przed wydaniem. W ustawieniach aplikacji iOS w Firebase osobno potwierdzić Team ID. W Apple Developer potwierdzić capability Sign in with Apple dla App ID i odświeżyć profile. Na fizycznym iPhonie przetestować pierwsze/ponowne logowanie oraz usunięcie konta Apple (ponowna autoryzacja i cofnięcie tokenu).
   **Anonymous można wyłączyć:** tryb gościa został usunięty, aplikacja wymaga logowania (Apple, Google lub e-mail). W App Review Information podać konto demo z potwierdzonym e-mailem.
4. **AdMob:** w sekcji Privacy & messaging opublikować komunikat GDPR/UMP dla aplikacji, uzupełnić dane płatności i `app-ads.txt`. W jednostce `drivioadrewarded` włączyć server-side verification i wpisać `https://europe-west1-drivio-a7d9c.cloudfunctions.net/admobRewardSsv`; bez podpisanego callbacku trzecia pułapka nie zostanie przyznana. Przetestować na iPhonie z urządzeniem oznaczonym jako testowe w AdMob.
5. **App Store Connect:** dodać trzy IAP do wersji wysyłanej do review, uzupełnić Agreements/Tax/Banking, lokalizacje, screenshot review i ceny. W App Privacy zaznaczyć m.in. Purchase History, User Content, Precise Location, Device ID i Advertising Data zgodnie z finalnym użyciem.
6. **Test urządzenia:** wykonać na fizycznym iPhonie: pierwsze/ponowne logowanie Apple, email relay, zakup każdego planu, restore, anulowanie, odnowienie sandbox, refund, zmianę konta, Pro bez reklam, konto darmowe z UMP i banerem. Na osobnym koncie testowym sprawdzić usunięcie po zalogowaniu Apple: ponowną autoryzację, cofnięcie tokenu, poprawny token App Check i usunięcie konta oraz danych Firebase. Nie używać do tego konta administratora.

## Ważne, ale nie blokuje pierwszego TestFlight

- Dodać Crashlytics lub Sentry i alerty budżetowe Firebase/Google Maps przed ruchem produkcyjnym.
- Debug może używać `REVENUECAT_TEST_API_KEY`; kod wybiera go tylko w buildzie debug. Przed wydaniem Androida ustawić osobny `REVENUECAT_ANDROID_API_KEY` i nie przekazywać klucza `test_` do release.
- Dodać istniejące testy do CI. Lokalnie przechodzi 11 testów Flutter, 22 testy reguł i 8 testów backendu RevenueCat.
- Włączyć alerty Firebase Usage and billing oraz ograniczyć Google Maps API key do Bundle ID `com.drivio.com` i właściwych API.
- Zweryfikować publiczne URL-e: support, privacy policy, marketing oraz procedurę odpowiedzi na zgłoszenia UGC.
