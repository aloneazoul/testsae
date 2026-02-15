import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class PostService {
  final ApiClient _client = ApiClient();

  static final StreamController<PostModel> _postUpdateController =
      StreamController.broadcast();
  static Stream<PostModel> get postUpdates => _postUpdateController.stream;

  static void notifyPostUpdated(PostModel post) {
    _postUpdateController.add(post);
  }

  static final StreamController<String> _postDeletionController =
      StreamController.broadcast();
  static Stream<String> get postDeletions => _postDeletionController.stream;

  static void notifyPostDeleted(String postId) {
    _postDeletionController.add(postId);
  }

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
      final Map<String, String> postData = {
        "post_description": description,
        "privacy": privacy,
        "allow_comments": allowComments.toString(),
      };

      if (latitude != null) postData["latitude"] = latitude.toString();
      if (longitude != null) postData["longitude"] = longitude.toString();
      if (tripId != null) postData["trip_id"] = tripId.toString();

      final response = await _client.postForm("/posts", postData);

      if (response == null || response["post_id"] == null) {
        return false;
      }

      final int postId = response["post_id"];
      if (imageFile != null) {
        await _client.postMultipart("/posts/$postId/media", imageFile);
      }

      return true;
    } catch (e) {
      print("❌ Erreur createPost: $e");
      return false;
    }
  }

  Future<List<dynamic>> getFeed({String type = "POST"}) async {
    try {
      final response = await _client.get("/posts/feed?post_type=$type");
      if (response != null && response is List) return response;
      return [];
    } catch (e) {
      print("❌ Erreur getFeed: $e");
      return [];
    }
  }

  Future<List<dynamic>> getMediaTripPosts(dynamic postId) async {
    try {
      final response = await _client.get("/posts/$postId/media");
      if (response != null && response is List) return response;
      return [];
    } catch (e) {
      print("❌ Erreur getMediaTripPosts: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFirstMediaTripPosts(int postId) async {
    try {
      final response = await _client.get("/posts/$postId/media/first");
      if (response != null && response is Map<String, dynamic>) return response;
      return null;
    } catch (e) {
      print("❌ Erreur getFirstMediaTripPosts: $e");
      return null;
    }
  }

  Future<List<dynamic>> getPosts() async {
    try {
      final response = await _client.get("/posts");
      if (response != null && response is List) return response;
      return [];
    } catch (e) {
      print("❌ Erreur getPosts: $e");
      return [];
    }
  }

  Future<bool> createCarouselPost({
    required int tripId,
    required List<File> imageFiles,
    String caption = "",
    required double latitude,
    required double longitude,
    String postType = "POST",
  }) async {
    final token = await StorageService.getToken();
    if (token == null) return false;

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
          "post_type": postType,
          "allow_comments": "true",
          "latitude": latitude.toString(),
          "longitude": longitude.toString(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        newPostId = data['post_id'];
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    if (newPostId == null) return false;

    bool allSuccess = true;
    final uploadUrl = Uri.parse("${_client.baseUrl}/posts/$newPostId/media");

    for (var file in imageFiles) {
      File fileToSend;
      
      final ext = p.extension(file.path).toLowerCase();
      if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
         fileToSend = await _compressVideo(file);
      } else {
         fileToSend = await _compressFile(file);
      }

      try {
        final request = http.MultipartRequest("POST", uploadUrl);
        request.headers['Authorization'] = "Bearer $token";
        request.files.add(
          await http.MultipartFile.fromPath('file', fileToSend.path),
        );
        final streamedResponse = await request.send();
        if (streamedResponse.statusCode != 200 &&
            streamedResponse.statusCode != 201) {
          allSuccess = false;
        }
      } catch (e) {
        allSuccess = false;
      }
    }
    return allSuccess;
  }

  Future<File> _compressFile(File file) async {
    final bytes = await file.length();
    if (bytes < 2000000) return file;

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1920,
      minHeight: 1920,
    );

    return result != null ? File(result.path) : file;
  }

  Future<File> _compressVideo(File file) async {
    try {
      if (await file.length() < 50 * 1024 * 1024) return file;

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      
      if (info != null && info.file != null) {
        return info.file!;
      }
      return file;
    } catch (e) {
      print("Erreur compression vidéo: $e");
      return file;
    }
  }

  // --- CORRECTION : CHANGEMENT TYPE INT -> STRING ---
  Future<bool> deletePost(String postId) async {
    try {
      await _client.delete("/posts/$postId");
      notifyPostDeleted(postId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getDiscoveryFeed({String type = "POST"}) async {
    final token = await StorageService.getToken();
    final url = "${_client.baseUrl}/feed/discovery?post_type=$type";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("🔴 Erreur réseau Feed : $e");
    }
    return [];
  }

  Future<List<dynamic>> getPostsByUser(String userId, {String type = "POST"}) async {
    try {
      final response = await _client.get("/posts/user/$userId?post_type=$type");
      if (response != null && response is List) return response;
      return [];
    } catch (e) {
      print("❌ Erreur getPostsByUser: $e");
      return [];
    }
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _client.post("/posts/$postId/like", {});
      return response != null && response['message'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlikePost(String postId) async {
    try {
      final response = await _client.delete("/posts/$postId/like");
      return response != null && response['message'] != null;
    } catch (e) {
      return false;
    }
  }
}