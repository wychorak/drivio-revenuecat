# Drivio — co zostało do konfiguracji

Stan po poprawkach z 18.09.2026:

- reguły Firestore są wdrożone do projektu `drivio-a7d9c`;
- zapis pułapek i szkół działa także dla starszych dokumentów użytkowników;
- klient nie może sam nadać sobie Premium;
- backend może nadać custom claim administratora zweryfikowanym kontom z listy `ADMIN_EMAILS`;
- komentarze, moderacja i reguły administratora mają testy;
- debug APK Android został zbudowany i zainstalowany na emulatorze.

Do wykonania w panelach zewnętrznych:

1. W RevenueCat utworzyć/pobrać **publiczny Android SDK key** (`goog_...`) i dodać go jako `REVENUECAT_ANDROID_API_KEY` do lokalnego `.env` oraz do zmiennych CI. Stara wersja projektu nie zawiera tego klucza.
2. W RevenueCat/Google Play powiązać produkty `drivioweek`, `driviomonth`, `driviolifetime` z offeringiem `driviooffers` i entitlementem `drivio pro relase`.
3. Dla nowej instalacji emulatora zarejestrować aktualny token debug Firebase App Check. Bez tego chronione funkcje `deleteAccount` i `refreshAdminClaim` poprawnie odrzucą wywołanie.
4. Webowe linki Stripe nie powinny trafić do produkcji, dopóki płatność nie zostanie powiązana z tym samym użytkownikiem RevenueCat/Firebase i przetestowana end to end.

Backend Firebase, sekret webhooka, konta administratorów, konfiguracja RevenueCat
dla App Store oraz Apple Server Notifications są już wdrożone.

Nie zapisuj prywatnych kluczy sklepu ani sekretu webhooka w repozytorium.
