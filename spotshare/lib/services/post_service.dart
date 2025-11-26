import 'dart:io';
import 'package:spotshare/services/api_client.dart';

class PostService {
  final ApiClient _client = ApiClient();

  /// Crée un post et upload l'image associée si elle existe.
  /// Retourne true si tout s'est bien passé.
  Future<bool> createPost({
    required String description,
    required File? imageFile,
    String privacy = "PUBLIC",
    bool allowComments = true,
    double? latitude,
    double? longitude,
    int? tripId,
  }) async {
    try {
      // 1. Préparer les données du formulaire pour la création du post
      // (Conforme aux champs attendus dans routers/posts.py)
      final Map<String, String> postData = {
        "post_description": description,
        "privacy": privacy,
        "allow_comments": allowComments.toString(),
      };

      if (latitude != null) postData["latitude"] = latitude.toString();
      if (longitude != null) postData["longitude"] = longitude.toString();
      if (tripId != null) postData["trip_id"] = tripId.toString();

      // 2. Appel API pour créer le post (sans l'image d'abord)
      final response = await _client.postForm("/posts", postData);

      if (response == null || response["post_id"] == null) {
        print("❌ Échec de la création du post (pas d'ID reçu)");
        return false;
      }

      final int postId = response["post_id"];
      print("✅ Post créé avec ID: $postId");

      // 3. Si une image est fournie, on l'upload via l'endpoint dédié
      if (imageFile != null) {
        await _client.postMultipart("/posts/$postId/media", imageFile);
        print("✅ Média uploadé pour le post $postId");
      }

      return true;
    } catch (e) {
      print("❌ Erreur dans PostService.createPost: $e");
      return false;
    }
  }

  /// Récupérer le fil d'actualité (Feed)
  Future<List<dynamic>> getFeed() async {
    try {
      final response = await _client.get("/posts/feed");
      if (response != null && response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("❌ Erreur getFeed: $e");
      return [];
    }
  }

  // Récupérer les medias d'un post d'un voyage spécifique
  Future<List<dynamic>> getMediaTripPosts(int postId) async {
    try {
      final response = await _client.get("/posts/$postId/media");
      if (response != null && response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("❌ Erreur getMediaTripPosts: $e");
      return [];
    }
  }

  // Récupérer le premier media d'un post d'un voyage spécifique
  Future<Map<String, dynamic>?> getFirstMediaTripPosts(int postId) async {
    try {
      final response = await _client.get("/posts/$postId/media/first");

      if (response == null) return null;
      if (response is Map<String, dynamic>) return response;

      return null;
    } catch (e) {
      print("❌ Erreur getFirstMediaTripPosts: $e");
      return null;
    }
  }
}
