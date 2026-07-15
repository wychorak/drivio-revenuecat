class ContentModerationService {
  static const _blockedTerms = {
    'kurwa',
    'chuj',
    'pierd',
    'jeb',
    'spierdal',
    'nienawidze',
  };

  static String? validateText(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return 'Treść nie może być pusta.';
    if (_containsBlockedTerm(normalized)) {
      return 'Treść zawiera niedozwolone słowa.';
    }
    if (_looksLikeSpam(normalized)) {
      return 'Treść wygląda jak spam.';
    }
    return null;
  }

  static String? validateFields(Iterable<String> values) {
    for (final value in values) {
      final result = validateText(value);
      if (result != null) return result;
    }
    return null;
  }

  static bool _containsBlockedTerm(String value) {
    return _blockedTerms.any(value.contains);
  }

  static bool _looksLikeSpam(String value) {
    final linkCount = RegExp(r'https?://|www\.').allMatches(value).length;
    if (linkCount > 1) return true;
    return RegExp(r'(.)\1{8,}').hasMatch(value);
  }
}
