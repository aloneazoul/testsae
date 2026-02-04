import 'dart:io';
import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/models/story_model.dart'; // Import ajouté
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StoryService {
  final ApiClient _client = ApiClient();

  /// Récupère le flux des stories (groupé par utilisateur) pour la Home Page
  /// Retourne maintenant une List<UserStoryGroup> typée
  Future<List<UserStoryGroup>> getStoriesFeed() async {
    try {
      final response = await _client.get("/stories/feed");
      if (response != null && response is List) {
        // Conversion explicite du JSON en modèles
        return response.map((json) => UserStoryGroup.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("⚠️ Erreur getStoriesFeed: $e");
      return [];
    }
  }

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

  Future<bool> postStory({
    required File file,
    String? caption,
    double? latitude,
    double? longitude,
  }) async {
    try {
      File fileToSend = file;
      final extension = p.extension(file.path).toLowerCase();
      final isImage = ['.jpg', '.jpeg', '.png', '.heic'].contains(extension);

      if (isImage) {
        final compressedFile = await _compressImage(file);
        if (compressedFile != null) fileToSend = compressedFile;
      }

      Map<String, String> fields = { "caption": caption ?? "" };
      if (latitude != null) fields["latitude"] = latitude.toString();
      if (longitude != null) fields["longitude"] = longitude.toString();

      final response = await _client.postMultipart("/stories", fileToSend, fields: fields);
      return response != null;
    } catch (e) {
      print("⚠️ Erreur postStory: $e");
      return false;
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, targetPath, quality: 80, minWidth: 1080, minHeight: 1920,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> viewStory(int storyId) async {
    try {
      await _client.post("/stories/$storyId/view", {});
    } catch (e) {
      print("⚠️ Erreur viewStory: $e");
    }
  }

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