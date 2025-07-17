
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Seleziona un'immagine dalla galleria o fotocamera con compressione ottimizzata
  Future<XFile?> pickImage() async {
    try {
      if (kIsWeb) {
        // Per il web, usa solo la galleria con compressione più aggressiva
        return await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 300,  // Ridotto da 512
          maxHeight: 300, // Ridotto da 512
          imageQuality: 70, // Ridotto da 85
        );
      } else {
        // Per mobile, mostra le opzioni con compressione più aggressiva
        return await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 300,  // Ridotto da 512
          maxHeight: 300, // Ridotto da 512
          imageQuality: 70, // Ridotto da 85
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Comprime ulteriormente l'immagine se necessario
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Se l'immagine è già piccola, restituiscila così com'è
    if (bytes.length <= 500 * 1024) { // 500KB
      return bytes;
    }

    // Per ora restituiamo i bytes originali
    // In futuro si può integrare un package come flutter_image_compress
    print('Image size: ${bytes.length} bytes');
    return bytes;
  }

  /// Carica un'immagine su Firebase Storage con ottimizzazioni
  Future<String?> uploadImage(XFile imageFile, String passwordId, {Function(double)? onProgress}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Leggi i bytes dell'immagine
      final bytes = await imageFile.readAsBytes();
      
      // Verifica dimensione file (max 1MB)
      if (bytes.length > 1024 * 1024) {
        print('Image too large: ${bytes.length} bytes');
        throw Exception('Immagine troppo grande. Seleziona un\'immagine più piccola.');
      }

      // Comprimi l'immagine se necessario
      final compressedBytes = await _compressImage(bytes);

      // Crea un percorso unico per l'immagine
      final String fileName = '${passwordId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'users/${user.uid}/password_images/$fileName';

      // Carica il file con metadati ottimizzati
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'max-age=31536000', // Cache per 1 anno
          customMetadata: {
            'passwordId': passwordId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalSize': bytes.length.toString(),
            'compressedSize': compressedBytes.length.toString(),
          },
        ),
      );

      // Monitora il progresso se richiesto
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Aspetta il completamento
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload completed: $downloadUrl');
      print('Original size: ${bytes.length} bytes, Compressed: ${compressedBytes.length} bytes');
      
      return downloadUrl;
      
    } catch (e) {
      print('Error uploading image: $e');
      rethrow; // Rilancia l'errore per gestirlo nell'UI
    }
  }

  /// Carica un'immagine con retry automatico
  Future<String?> uploadImageWithRetry(XFile imageFile, String passwordId, {Function(double)? onProgress, int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await uploadImage(imageFile, passwordId, onProgress: onProgress);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          print('Upload failed after $maxRetries attempts: $e');
          return null;
        }
        
        // Aspetta prima di riprovare (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
        print('Retry attempt $attempts for image upload');
      }
    }
    
    return null;
  }

  /// Elimina un'immagine da Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Precarica un'immagine per il caching
  Future<void> preloadImage(String imageUrl) async {
    try {
      if (kIsWeb) {
        // Per il web, forza il download per il caching del browser
        final ref = _storage.refFromURL(imageUrl);
        await ref.getDownloadURL();
      }
    } catch (e) {
      print('Error preloading image: $e');
    }
  }

  /// Ottiene le icone predefinite per i servizi comuni
  Map<String, String> getPresetIcons() {
    return {
      'Gmail': '📧',
      'Facebook': '📘',
      'Instagram': '📷',
      'Twitter': '🐦',
      'LinkedIn': '💼',
      'GitHub': '🐙',
      'Discord': '🎮',
      'Netflix': '🎬',
      'Spotify': '🎵',
      'YouTube': '📹',
      'Amazon': '📦',
      'PayPal': '💳',
      'Apple': '🍎',
      'Microsoft': '🪟',
      'Google': '🔍',
      'Dropbox': '📁',
      'Steam': '🎯',
      'Reddit': '🤖',
      'Twitch': '🎭',
      'WhatsApp': '💬',
    };
  }

  /// Ottiene l'emoji per un titolo se disponibile
  String? getEmojiForTitle(String title) {
    final presetIcons = getPresetIcons();
    for (final key in presetIcons.keys) {
      if (title.toLowerCase().contains(key.toLowerCase())) {
        return presetIcons[key];
      }
    }
    return null;
  }
} 