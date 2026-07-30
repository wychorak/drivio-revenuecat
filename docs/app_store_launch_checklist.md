# Drivio — release readiness (30 lipca 2026)

## Gotowe w kodzie

- iOS używa Bundle ID `com.drivio.com`, a App Store Connect ID to `6776345734`.
- Codemagic importuje grupę zmiennych `drivio secrets`, waliduje Firebase, Maps, admina i kontakt oraz przekazuje wartości przez `--dart-define`.
- Logowanie Apple używa Firebase Auth, aplikacja ma capability `Sign in with Apple`, a dokument użytkownika powstaje również po tym logowaniu.
- RevenueCat używa offeringu `driviooffers`, entitlementu `drivio pro relase` i produktów `drivioweek`, `driviomonth`, `driviolifetime`.
- Zakup jest uznany za udany dopiero po aktywacji entitlementu. Jest restore, identyfikacja Firebase UID i ceny ze StoreKit.
- Paywall zawiera informację o odnowieniu, zakupie lifetime, regulaminie i polityce prywatności.
- AdMob iOS używa aplikacji `ca-app-pub-8263324816746737~5489467107` i banera `ca-app-pub-8263324816746737/9237140422`.
- Reklama to wyłącznie kompaktowy baner nad dolną nawigacją. Brak interstitiali i reklam przy starcie. Drivio Pro nigdy nie ładuje banera.
- Debug build używa testowego ID Google. Produkcja żąda reklam niepersonalizowanych i przechodzi przez UMP przed pierwszym żądaniem.
- Firebase App Check jest aktywowany w aplikacji: App Attest z fallbackiem DeviceCheck na iOS, Play Integrity na Androidzie i provider debug w debug buildzie.
- Firestore i Storage mają reguły default-deny, walidację pól, ownership, limity list/uploadu i custom claim `admin`.
- Limit darmowych pułapek jest transakcyjnym, nieusuwalnym licznikiem w 24-godzinnym oknie, a nie tylko kontrolą UI.
- Konto admin wymaga jednocześnie: emailu z `ADMIN_EMAILS`, zweryfikowanego emailu Firebase i custom claimu `admin=true`.
- Admin ma kolejkę zgłoszeń i może odrzucić zgłoszenie lub usunąć zgłoszoną treść.
- Usunięcie konta usuwa własne komentarze, zgłoszenia, pułapki, zdjęcia, dokument użytkownika i konto Firebase; starsza sesja wymaga ponownego logowania.
- Finalne ikony Drivio i splash screen zostały wygenerowane dla iOS, Androida, macOS, Windows i web.
- Polityka prywatności, manifest prywatności i regulamin opisują AdMob oraz brak reklamy behawioralnej.

## Blokery w panelach — wykonać przed TestFlight

1. **Codemagic:** grupa musi nazywać się dokładnie `drivio secrets`. Na załączonym ekranie widać Maps/admin/kontakt, ale build wymaga też `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` i `FIREBASE_STORAGE_BUCKET`.
2. **Firebase Rules:** partner musi wdrożyć `firebase/firestore.rules`, `firebase/storage.rules` i indeksy. Polecenie: `firebase deploy --only firestore:rules,firestore:indexes,storage --project <FIREBASE_PROJECT_ID>`.
3. **Admin:** zaufane środowisko Firebase Admin SDK musi nadać właściwemu UID custom claim `{ admin: true }`. Po nadaniu wylogować i zalogować konto. Samo `ADMIN_EMAILS` nie daje uprawnień.
4. **App Check:** zarejestrować `com.drivio.com` w Firebase App Check, najpierw obserwować metryki TestFlight, a potem włączyć enforcement dla Firestore, Storage i Authentication. Nie włączać enforcement przed pierwszym poprawnym tokenem z TestFlight.
5. **Apple login:** w Firebase Authentication włączyć Apple i uzupełnić Team ID, Key ID `6D43VGP33F` oraz prywatny `.p8` klucza `driviokey`. W Apple Developer włączyć capability dla App ID `com.drivio.com` i odświeżyć profile.
6. **RevenueCat:** dodać klucz App Store Connect/IAP, ustawić `driviooffers` jako Current, upewnić się, że wszystkie trzy produkty odblokowują dokładnie `drivio pro relase` i mają status pozwalający na test. Prywatnego `.p8` nie dodawać do repo ani Firebase klienta.
7. **AdMob:** w sekcji Privacy & messaging opublikować komunikat GDPR/UMP dla aplikacji, uzupełnić dane płatności i `app-ads.txt`. Bez opublikowanego komunikatu UMP baner może legalnie się nie załadować.
8. **App Store Connect:** dodać trzy IAP do wersji wysyłanej do review, uzupełnić Agreements/Tax/Banking, lokalizacje, screenshot review i ceny. W App Privacy zaznaczyć m.in. Purchase History, User Content, Precise Location, Device ID i Advertising Data zgodnie z finalnym użyciem.
9. **Test urządzenia:** wykonać na fizycznym iPhonie: pierwsze/ponowne logowanie Apple, email relay, zakup każdego planu, restore, anulowanie, odnowienie sandbox, refund, zmianę konta, Pro bez reklam, konto darmowe z UMP i banerem, usunięcie konta.

## Ważne, ale nie blokuje pierwszego TestFlight

- Dodać Crashlytics lub Sentry i alerty budżetowe Firebase/Google Maps przed ruchem produkcyjnym.
- Skonfigurować webhook RevenueCat lub Firebase Extension, jeśli pola `isPremium`/`premiumUntil` w Firestore mają być wiarygodnym serwerowym fallbackiem.
- Dodać automatyczne testy przypadków allow/deny do CI. Reguły zostały już poprawnie skompilowane lokalnie przez Firestore Emulator 1.22.0 na Java 21.
- Włączyć alerty Firebase Usage and billing oraz ograniczyć Google Maps API key do Bundle ID `com.drivio.com` i właściwych API.
- Zweryfikować publiczne URL-e: support, privacy policy, marketing oraz procedurę odpowiedzi na zgłoszenia UGC.