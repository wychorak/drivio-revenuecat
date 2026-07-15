import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/user_model.dart';

class DevDataService {
  static const devUserId = 'dev-admin';

  static final adminUser = UserModel(
    uid: devUserId,
    email: 'dev-admin@drivio.local',
    displayName: 'Dev Admin',
    isPremium: true,
    premiumUntil: DateTime(2099, 12, 31),
    savedTraps: const ['dev-trap-1', 'dev-trap-3'],
    savedSchools: const ['dev-school-1'],
  );

  static List<TrapModel> traps(String city) {
    final normalizedCity = city.trim().isEmpty ? 'Szczecin' : city.trim();
    final center = _cityCenter(normalizedCity);
    return [
      TrapModel(
        id: 'dev-trap-1',
        lat: center.$1 + 0.004,
        lng: center.$2 - 0.004,
        title: 'Lewoskret na skrzyzowaniu',
        description:
            'Lokalny przyklad do testow: czeste wymuszenie pierwszenstwa przy skrecie w lewo.',
        difficulty: 4,
        ruleDescription:
            'Przed skretem w lewo upewnij sie, ze masz pierwszenstwo i obserwuj pieszych oraz rowerzystow.',
        createdBy: 'dev-instructor',
        city: normalizedCity,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        savesCount: 7,
      ),
      TrapModel(
        id: 'dev-trap-2',
        lat: center.$1 - 0.006,
        lng: center.$2 + 0.005,
        title: 'Uwaga na znak STOP',
        description:
            'Punkt kontrolny do sprawdzenia markerow, szczegolow pulapki i komentarzy.',
        difficulty: 3,
        ruleDescription:
            'Zatrzymaj pojazd przed linia zatrzymania lub w miejscu z dobra widocznoscia.',
        createdBy: 'dev-user-1',
        city: normalizedCity,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        savesCount: 4,
      ),
      TrapModel(
        id: 'dev-trap-3',
        lat: center.$1 + 0.009,
        lng: center.$2 + 0.002,
        title: 'Zmiana pasa przed rondem',
        description:
            'Testowy scenariusz do premium oraz listy zapisanych pulapek.',
        difficulty: 5,
        videoUrl: 'https://example.com/dev-video.mp4',
        ruleDescription:
            'Zaplanuj pas odpowiednio wczesnie, sygnalizuj manewr i nie zajezdzaj drogi.',
        createdBy: 'dev-instructor',
        city: normalizedCity,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        savesCount: 12,
      ),
    ];
  }

  static TrapModel? trapById(String id) {
    for (final city in const ['Szczecin', 'Warszawa']) {
      for (final trap in traps(city)) {
        if (trap.id == id) return trap;
      }
    }
    return null;
  }

  static List<SchoolModel> schools(String city) {
    final normalizedCity = city.trim().isEmpty ? 'Szczecin' : city.trim();
    final center = _cityCenter(normalizedCity);
    return [
      SchoolModel(
        id: 'dev-school-1',
        name: 'Drivio OSK Demo',
        rating: 4.8,
        reviewCount: 38,
        priceFrom: 3200,
        priceTo: 3900,
        address: '$normalizedCity, ul. Testowa 12',
        description:
            'Lokalna szkola demo do budowy aplikacji bez dostepu do Firestore.',
        lat: center.$1 - 0.003,
        lng: center.$2 - 0.007,
        phone: '+48123123123',
        website: 'https://example.com',
      ),
      SchoolModel(
        id: 'dev-school-2',
        name: 'Auto Start Demo',
        rating: 4.4,
        reviewCount: 21,
        priceFrom: 2900,
        priceTo: 3600,
        address: '$normalizedCity, al. Lokalna 8',
        description:
            'Drugi rekord testowy do list, mapy i ekranu szczegolow szkoly.',
        lat: center.$1 + 0.007,
        lng: center.$2 + 0.006,
        phone: '+48999888777',
        website: 'https://example.org',
      ),
    ];
  }

  static SchoolModel? schoolById(String id) {
    for (final city in const ['Szczecin', 'Warszawa']) {
      for (final school in schools(city)) {
        if (school.id == id) return school;
      }
    }
    return null;
  }

  static List<CommentModel> comments(String itemId, String itemType) {
    return [
      CommentModel(
        id: 'dev-comment-1-$itemId',
        itemId: itemId,
        itemType: itemType,
        userId: 'dev-instructor',
        userDisplayName: 'Instruktor Demo',
        text: itemType == 'trap'
            ? 'Tu zwykle kursanci za pozno patrza w lewo.'
            : 'Dobry kontakt i szybkie terminy jazd.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      CommentModel(
        id: 'dev-comment-2-$itemId',
        itemId: itemId,
        itemType: itemType,
        userId: 'dev-user-1',
        userDisplayName: 'Kursant Demo',
        text: 'Komentarz lokalny, bez zapisu do Firestore.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<TrapModel> savedTraps(List<String> ids) {
    final all = traps('Szczecin') + traps('Warszawa');
    return all.where((trap) => ids.contains(trap.id)).toList();
  }

  static List<SchoolModel> savedSchools(List<String> ids) {
    final all = schools('Szczecin') + schools('Warszawa');
    return all.where((school) => ids.contains(school.id)).toList();
  }

  static (double, double) _cityCenter(String city) {
    if (city.toLowerCase().contains('warsz')) {
      return (52.2297, 21.0122);
    }
    return (53.4289, 14.5530);
  }
}
