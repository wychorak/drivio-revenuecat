import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drivio/features/theory_exam/models.dart';

/// Where theory exam progress lives. Device-only for now; a cloud-synced
/// implementation can replace it without touching the screens.
abstract class TheoryProgressRepository {
  Future<TheoryProgress> load();
  Future<void> save(TheoryProgress progress);
}

class SharedPrefsTheoryProgressRepository implements TheoryProgressRepository {
  static const storageKey = 'theoryExam.progress.v1';

  @override
  Future<TheoryProgress> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(storageKey);
    if (raw == null) return TheoryProgress.empty();
    try {
      return TheoryProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      // A damaged or outdated entry must never block the section.
      debugPrint('Theory progress unreadable, starting fresh: $error');
      return TheoryProgress.empty();
    }
  }

  @override
  Future<void> save(TheoryProgress progress) async {
    await (await SharedPreferences.getInstance()).setString(
      storageKey,
      jsonEncode(progress.toJson()),
    );
  }
}
