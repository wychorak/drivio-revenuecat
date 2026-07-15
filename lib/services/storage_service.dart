import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _extension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot);
  }

  Future<String> uploadTrapPhoto(String uid, File imageFile) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${_extension(imageFile.path)}';
    final ref = _storage.ref().child('traps/$uid/$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (_) {
      // Ignore errors if file doesn't exist
    }
  }
}
