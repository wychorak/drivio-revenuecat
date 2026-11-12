/// When the theory section may show a full-screen (interstitial) ad.
///
/// Only at natural breaks: after every [answersBetween] practice answers and
/// after a finished exam, never during a timed question. All limits live
/// here so they are easy to tune.
class TheoryAdPolicy {
  TheoryAdPolicy({
    required this.sectionEnteredAt,
    this.answersBetween = 10,
    this.minGap = const Duration(minutes: 3),
    this.warmup = const Duration(minutes: 2),
  });

  final DateTime sectionEnteredAt;
  final int answersBetween;
  final Duration minGap;
  final Duration warmup;

  int _answersSinceAd = 0;
  DateTime? _lastShown;

  bool _timeAllows(DateTime now) =>
      !now.isBefore(sectionEnteredAt.add(warmup)) &&
      (_lastShown == null || !now.isBefore(_lastShown!.add(minGap)));

  /// Counts a practice answer; true when an ad should be shown now.
  bool onAnswer(DateTime now, {required bool premium}) {
    if (premium) return false;
    _answersSinceAd++;
    return _answersSinceAd >= answersBetween && _timeAllows(now);
  }

  /// True when an ad should be shown before the exam result.
  bool onExamFinished(DateTime now, {required bool premium}) =>
      !premium && _timeAllows(now);

  void markShown(DateTime now) {
    _lastShown = now;
    _answersSinceAd = 0;
  }
}
