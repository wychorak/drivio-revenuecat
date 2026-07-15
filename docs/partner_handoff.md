# Drivio — handoff dla Firebase, RevenueCat i wydania

## RevenueCat / zakupy Apple

Aplikacja Flutter korzysta teraz z RevenueCat. Publiczny klucz iOS jest podłączony po stronie klienta.

Konfiguracja wymagana w panelu RevenueCat:

- offering: driviooffers (ustawić jako Current);
- entitlement: drivio pro relase;
- pakiet $rc_weekly -> produkt drivioweek;
- pakiet $rc_monthly -> produkt driviomonth;
- pakiet $rc_lifetime -> produkt driviolifetime.

Wszystkie trzy produkty muszą odblokowywać entitlement drivio pro relase. Produkty drivioweek i driviomonth powinny być Auto-Renewable Subscriptions, a driviolifetime — Non-Consumable. Nie należy tworzyć produktu lifetime jako subskrypcji ani consumable.

W RevenueCat trzeba podłączyć aplikację App Store Connect o Bundle ID com.drivio.com i dodać wymagane dane App Store Connect / In-App Purchase Key. Klucz publiczny RevenueCat może być w aplikacji; prywatne klucze Apple .p8 mogą być wyłącznie sekretem RevenueCat, backendu albo CI.

## Firestore / backend

Firestore pozostaje w projekcie. RevenueCat jest źródłem prawdy dla aktywnego Premium w aplikacji, a istniejące pola Firestore są zachowane jako kompatybilny fallback.

Po stronie backendu zalecane jest:

- skonfigurować webhook RevenueCat albo oficjalną integrację z Firebase;
- po zdarzeniach zakupu, odnowienia, wygaśnięcia i zwrotu synchronizować users/{uid};
- zapisywać co najmniej isPremium, premiumUntil, premiumPlan, premiumProductId, premiumSource, premiumStore i premiumUpdatedAt;
- blokować klientowi bezpośrednią edycję pól Premium w Firestore Rules;
- sprawdzić reguły dla komentarzy, pułapek, rankingów, zdjęć i danych profilu;
- upewnić się, że dokument użytkownika powstaje po każdym rodzaju logowania.

Nie trzeba dodawać własnej walidacji paragonów w aplikacji mobilnej — zakup i uprawnienia weryfikuje RevenueCat. Backend powinien reagować na webhooki, jeśli Firestore ma odzwierciedlać stan Premium.

## Logowanie przez Apple

Po stronie aplikacji jest gotowy natywny flow Firebase Auth i entitlement Sign in with Apple. Przed testem trzeba:

- w Apple Developer włączyć Sign in with Apple dla App ID com.drivio.com;
- odświeżyć provisioning profile;
- w Firebase Authentication włączyć provider Apple;
- w Firebase użyć klucza Apple driviokey, Key ID 6D43VGP33F; po otrzymaniu pliku .p8 uzupełnić także Team ID i prywatny klucz;
- skonfigurować domenę przekazywania e-maili Apple dla wiadomości wysyłanych do adresów privaterelay;
- przetestować pierwsze logowanie, ponowne logowanie i usunięcie konta na fizycznym iPhonie.

Prywatnego klucza Apple nie dodawać do repozytorium ani aplikacji.

## Konfiguracja i sekrety

- Prawdziwe pliki Firebase i sekrety trzymać poza repo: .env, GoogleService-Info.plist, google-services.json i Secrets.xcconfig.
- Skonfigurować wartości produkcyjne przez sekrety CI albo dart-define.
- Sprawdzić ograniczenia kluczy Google Maps dla iOS i Androida.
- Dla zakupów na Androidzie dodać REVENUECAT_ANDROID_API_KEY i osobne produkty Google Play.
- Skonfigurować produkcyjne podpisywanie Androida — build release nie może używać debug keystore.

## Testy przed wysłaniem

- Dodać wszystkie trzy IAP do wersji aplikacji wysyłanej do App Review.
- Uzupełnić ceny, lokalizacje, opisy i screenshoty produktów.
- Sprawdzić Agreements, Tax and Banking.
- Utworzyć Sandbox Testerów i wykonać zakup każdego planu, anulowanie, restore i zwrot.
- Sprawdzić, czy Premium pozostaje aktywne po ponownym uruchomieniu i ponownym logowaniu.
- Przejść cały flow: wybór miasta, logowanie, mapa, pułapki, komentarze, profil, limity i Premium.
- Wykonać archive na macOS/Xcode oraz testy TestFlight na fizycznym iPhonie.