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
    if (await imageFile.length() > 5 * 1024 * 1024) {
      throw const FormatException('Zdjęcie może mieć maksymalnie 5 MB.');
    }
    final extension = _extension(imageFile.path).toLowerCase();
    final contentType = switch (extension) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      _ => throw const FormatException(
        'Wybierz zdjęcie JPG, PNG, WebP lub HEIC.',
      ),
    };
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final ref = _storage.ref().child('traps/$uid/$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: contentType),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadTrapVideo(String uid, File videoFile) async {
    const maxBytes = 100 * 1024 * 1024;
    if (await videoFile.length() > maxBytes) {
      throw const FormatException('Film może mieć maksymalnie 100 MB.');
    }
    final extension = _extension(videoFile.path).toLowerCase();
    final contentType = switch (extension) {
      '.mp4' => 'video/mp4',
      '.mov' => 'video/quicktime',
      '.m4v' => 'video/x-m4v',
      _ => throw const FormatException('Wybierz film MP4, MOV lub M4V.'),
    };
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final ref = _storage.ref().child('traps/$uid/videos/$fileName');
    final snapshot = await ref.putFile(
      videoFile,
      SettableMetadata(contentType: contentType),
    );
    return snapshot.ref.getDownloadURL();
  }

  Future<void> deleteUploadedMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore errors if file doesn't exist
    }
  }

  Future<void> deletePhoto(String photoUrl) => deleteUploadedMedia(photoUrl);
}
