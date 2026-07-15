import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/dev_data_service.dart';

final schoolsProvider = StreamProvider.family<List<SchoolModel>, String>((
  ref,
  city,
) {
  final devLogin = ref.watch(devLoginProvider);
  if (devLogin) {
    return Stream.value(DevDataService.schools(city));
  }
  return ref.watch(firestoreServiceProvider).getSchools(city);
});

final selectedSchoolProvider = StateProvider<SchoolModel?>((ref) => null);
