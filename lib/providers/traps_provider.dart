import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/services/daily_limit_service.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/providers/auth_provider.dart';

final trapsProvider = StreamProvider.family<List<TrapModel>, String>((
  ref,
  city,
) {
  final devLogin = ref.watch(devLoginProvider);
  final blockedUsers =
      ref.watch(currentUserProvider).value?.blockedUsers.toSet() ?? {};
  if (devLogin) {
    return Stream.value(
      DevDataService.traps(
        city,
      ).where((trap) => !blockedUsers.contains(trap.createdBy)).toList(),
    );
  }
  return ref
      .watch(firestoreServiceProvider)
      .getTraps(city)
      .map(
        (traps) => traps
            .where((trap) => !blockedUsers.contains(trap.createdBy))
            .toList(),
      );
});

final selectedTrapProvider = StateProvider<TrapModel?>((ref) => null);

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  itemId,
) {
  final devLogin = ref.watch(devLoginProvider);
  final blockedUsers =
      ref.watch(currentUserProvider).value?.blockedUsers.toSet() ?? {};
  if (devLogin) {
    return Stream.value(
      DevDataService.comments(
        itemId,
        'trap',
      ).where((comment) => !blockedUsers.contains(comment.userId)).toList(),
    );
  }
  return ref
      .watch(firestoreServiceProvider)
      .getComments(itemId, 'trap')
      .map(
        (comments) => comments
            .where((comment) => !blockedUsers.contains(comment.userId))
            .toList(),
      );
});

final schoolCommentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, itemId) {
      final devLogin = ref.watch(devLoginProvider);
      final blockedUsers =
          ref.watch(currentUserProvider).value?.blockedUsers.toSet() ?? {};
      if (devLogin) {
        return Stream.value(
          DevDataService.comments(
            itemId,
            'school',
          ).where((comment) => !blockedUsers.contains(comment.userId)).toList(),
        );
      }
      return ref
          .watch(firestoreServiceProvider)
          .getComments(itemId, 'school')
          .map(
            (comments) => comments
                .where((comment) => !blockedUsers.contains(comment.userId))
                .toList(),
          );
    });

final dailyLimitServiceProvider = Provider<DailyLimitService>((ref) {
  return DailyLimitService();
});

final remainingViewsProvider = FutureProvider<TrapViewStatus>((ref) async {
  final devLogin = ref.watch(devLoginProvider);
  if (devLogin) {
    return const TrapViewStatus(
      allowed: true,
      premium: true,
      freeRemaining: AppConfig.freeDailyTrapLimit,
      totalRemaining: AppConfig.freeDailyTrapLimit,
      rewardGranted: false,
      canWatchAd: false,
    );
  }

  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return const TrapViewStatus(
      allowed: false,
      premium: false,
      freeRemaining: 0,
      totalRemaining: 0,
      rewardGranted: false,
      canWatchAd: false,
    );
  }
  return ref.watch(dailyLimitServiceProvider).getStatus();
});
