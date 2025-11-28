import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:path/path.dart' as p;

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

  // Récupérer les posts d'un post d'un voyage spécifique
  Future<List<dynamic>> getPosts() async {
    try {
      final response = await _client.get("/posts");
      if (response != null && response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("❌ Erreur getPosts: $e");
      return [];
    }
  }

  // --- MÉTHODE CARROUSEL (MISE À JOUR AVEC COMPRESSION) ---

  Future<bool> createCarouselPost({
    required int tripId,
    required List<File> imageFiles,
    String caption = "",
  }) async {
    final token = await StorageService.getToken();
    if (token == null) {
      print("🔴 Erreur: Pas de token auth");
      return false;
    }

    print("🔵 Début création post carrousel pour voyage $tripId...");

    // 1. Créer le post
    final createUrl = Uri.parse("${_client.baseUrl}/posts");
    int? newPostId;

    try {
      final response = await http.post(
        createUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "trip_id": tripId.toString(),
          "post_description": caption,
          "privacy": "PUBLIC",
          "allow_comments": "true",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        newPostId = data['post_id'];
      } else {
        print("❌ Erreur création post: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔴 Exception création post: $e");
      return false;
    }

    if (newPostId == null) return false;

    // 2. Uploader les images UNE PAR UNE avec compression
    bool allSuccess = true;
    final uploadUrl = Uri.parse("${_client.baseUrl}/posts/$newPostId/media");
    print(imageFiles);

    for (var file in imageFiles) {
      // ---> COMPRESSION ICI <---
      File fileToSend = await _compressFile(file);

      print("📤 Envoi image: ${fileToSend.path.split('/').last}...");
      try {
        final request = http.MultipartRequest("POST", uploadUrl);
        request.headers['Authorization'] = "Bearer $token";
        request.files.add(
          await http.MultipartFile.fromPath('file', fileToSend.path),
        );

        final streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 201) {
          print("   ✅ Image uploadée");
        } else {
          allSuccess = false;
          print(
            "   ❌ ÉCHEC (Code ${streamedResponse.statusCode}) : $responseBody",
          );
        }
      } catch (e) {
        print("   🔴 Exception upload: $e");
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  // --- UTILITAIRE : COMPRESSION ---
  Future<File> _compressFile(File file) async {
    final filePath = file.absolute.path;

    // Si l'image fait moins de 2 Mo, on ne la touche pas
    final bytes = await file.length();
    if (bytes < 2000000) {
      return file;
    }

    print(
      "🔄 Compression de l'image (${(bytes / 1024 / 1024).toStringAsFixed(2)} MB)...",
    );

    // Chemin de sortie dans le dossier temporaire
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80, // 80% qualité = grosse réduction de taille
      minWidth: 1920,
      minHeight: 1920,
    );

    if (result != null) {
      final newSize = await result.length();
      print(
        "✅ Image compressée : ${(newSize / 1024 / 1024).toStringAsFixed(2)} MB",
      );
      return File(result.path);
    }

    return file; // En cas d'erreur, on renvoie l'original
  }

  // Supprimer un post
  Future<bool> deletePost(int postId) async {
    try {
      await _client.delete("/posts/$postId");
      return true;
    } catch (e) {
      print("Erreur suppression voyage: $e");
      return false;
    }
  }
}
