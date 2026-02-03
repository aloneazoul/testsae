import 'dart:io';
import 'package:spotshare/services/api_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StoryService {
  final ApiClient _client = ApiClient();

  /// Récupère le flux des stories (groupé par utilisateur) pour la Home Page
  Future<List<dynamic>> getStoriesFeed() async {
    try {
      final response = await _client.get("/stories/feed");
      if (response != null && response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("⚠️ Erreur getStoriesFeed: $e");
      return [];
    }
  }

  /// Récupère les stories d'un utilisateur spécifique (pour la Profile Page)
  /// Retourne un objet contenant { "stories": [...], "all_seen": bool, ... }
  Future<Map<String, dynamic>?> getUserStories(String userId) async {
    try {
      final response = await _client.get("/stories/user/$userId");
      if (response != null && response is Map) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("⚠️ Erreur getUserStories: $e");
      return null;
    }
  }

  /// Publie une nouvelle story (Image ou Vidéo) avec compression automatique des images
  Future<bool> postStory({
    required File file,
    String? caption,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // 1. Compression si c'est une image (jpg, jpeg, png, heic)
      File fileToSend = file;
      final extension = p.extension(file.path).toLowerCase();
      final isImage = ['.jpg', '.jpeg', '.png', '.heic'].contains(extension);

      if (isImage) {
        print("🗜️ Compression de l'image avant envoi...");
        final compressedFile = await _compressImage(file);
        if (compressedFile != null) {
          fileToSend = compressedFile;
          print("✅ Image compressée : ${fileToSend.lengthSync()} bytes");
        } else {
          print("⚠️ Échec compression, envoi de l'original.");
        }
      }

      // 2. Préparation des champs
      Map<String, String> fields = {
        "caption": caption ?? "",
      };

      if (latitude != null) fields["latitude"] = latitude.toString();
      if (longitude != null) fields["longitude"] = longitude.toString();

      // 3. Envoi via ApiClient
      final response = await _client.postMultipart(
        "/stories", 
        fileToSend,
        fields: fields,
      );

      return response != null;
    } catch (e) {
      print("⚠️ Erreur postStory: $e");
      return false;
    }
  }

  /// Fonction utilitaire de compression
  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path, 
        "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg"
      );

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80, // Bonne qualité, taille réduite
        minWidth: 1080, // Résolution standard mobile
        minHeight: 1920,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      print("❌ Erreur compression: $e");
    }
    return null; // Retourne null si échec, on utilisera le fichier original
  }

  /// Marque une story spécifique comme vue
  Future<void> viewStory(int storyId) async {
    try {
      await _client.post("/stories/$storyId/view", {});
    } catch (e) {
      print("⚠️ Erreur viewStory: $e");
    }
  }

  /// Supprimer une story
  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await _client.delete("/stories/$storyId");
      return response != null;
    } catch (e) {
      print("⚠️ Erreur deleteStory: $e");
      return false;
    }
  }
}