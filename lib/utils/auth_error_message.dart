bool isAuthCancellation(Object error) {
  final value = error.toString().toLowerCase();
  return value.contains('cancelled') ||
      value.contains('canceled') ||
      value.contains('popup-closed-by-user') ||
      value.contains('web-context-cancelled');
}

String authErrorMessage(Object error, {bool providerLogin = false}) {
  final value = error.toString().toLowerCase();

  if (value.contains('user-not-found') ||
      value.contains('wrong-password') ||
      (!providerLogin && value.contains('invalid-credential'))) {
    return 'Nieprawidłowy e-mail lub hasło.';
  }
  if (value.contains('email-not-verified')) {
    return 'Potwierdź adres e-mail. Wysłaliśmy nowy link weryfikacyjny.';
  }
  if (value.contains('email-already-in-use')) {
    return 'Ten adres e-mail jest już używany.';
  }
  if (value.contains('account-exists-with-different-credential')) {
    return 'Konto z tym adresem istnieje już u innego dostawcy logowania.';
  }
  if (value.contains('weak-password')) {
    return 'Hasło jest zbyt słabe.';
  }
  if (value.contains('invalid-email')) {
    return 'Nieprawidłowy adres e-mail.';
  }
  if (providerLogin && value.contains('invalid-credential')) {
    return 'Nie udało się potwierdzić logowania u dostawcy.';
  }
  if (value.contains('operation-not-allowed')) {
    return 'Ten sposób logowania nie jest jeszcze aktywny w Firebase.';
  }
  if (value.contains('network-request-failed') ||
      value.contains('network_error')) {
    return 'Brak połączenia z internetem.';
  }
  if (value.contains('invalid-oauth-response') ||
      value.contains('invalid-oauth-client-id') ||
      value.contains('developer_error') ||
      value.contains('configuration')) {
    return 'Nie udało się uruchomić logowania. Sprawdź konfigurację dostawcy.';
  }
  if (value.contains('too-many-requests')) {
    return 'Za dużo prób. Spróbuj ponownie za chwilę.';
  }
  return 'Nie udało się zalogować. Spróbuj ponownie.';
}
