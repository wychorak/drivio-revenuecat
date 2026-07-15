import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/models/user_model.dart';
import 'package:drivio/services/auth_service.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/providers/user_provider.dart';

// DEV MODE: omija Firebase Auth — tylko do testów
final devLoginProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateStream;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final devLogin = ref.watch(devLoginProvider);
  if (devLogin) {
    return Stream.value(DevDataService.adminUser);
  }

  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).getUserData(user.uid);
    },
    loading: () => const Stream<UserModel?>.empty(),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  );
});
