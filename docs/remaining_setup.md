# Drivio — co zostało do konfiguracji

Stan po poprawkach z 18.09.2026:

- reguły Firestore są wdrożone do projektu `drivio-a7d9c`;
- zapis pułapek i szkół działa także dla starszych dokumentów użytkowników;
- klient nie może sam nadać sobie Premium;
- zweryfikowane konta `joa.rycyk@gmail.com` i `estlin20@gmail.com` mają dostęp administratora i Premium w aplikacji;
- komentarze, moderacja i reguły administratora mają testy;
- debug APK Android został zbudowany i zainstalowany na emulatorze.

Do wykonania w panelach zewnętrznych:

1. W RevenueCat utworzyć/pobrać **publiczny Android SDK key** (`goog_...`) i dodać go jako `REVENUECAT_ANDROID_API_KEY` do lokalnego `.env` oraz do zmiennych CI. Stara wersja projektu nie zawiera tego klucza.
2. W Google Cloud dla projektu `drivio-a7d9c` włączyć Cloud Functions API i plan rozliczeniowy wymagany przez Functions 2nd gen.
3. Ustawić sekret backendu poleceniem `firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH`, a następnie wdrożyć katalog `functions`.
4. Ten sam sekret i URL wdrożonej funkcji `revenueCatWebhook` ustawić w panelu RevenueCat.
5. W RevenueCat/Google Play powiązać produkty `drivioweek`, `driviomonth`, `driviolifetime` z offeringiem `driviooffers` i entitlementem `drivio pro relase`.
6. Konto administratora musi mieć potwierdzony adres e-mail w Firebase Authentication. Po weryfikacji trzeba wylogować się i zalogować ponownie, aby odświeżyć token.

Nie zapisuj prywatnych kluczy sklepu ani sekretu webhooka w repozytorium.
