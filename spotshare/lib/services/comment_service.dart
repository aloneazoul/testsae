// lib/services/comment_service.dart

import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/models/comment_model.dart';

class CommentService {
  final ApiClient _client = ApiClient();

  /// Récupère la liste des commentaires d'un post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await _client.get("/posts/$postId/comments");
      if (response != null && response is List) {
        return response.map((e) => CommentModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur getComments: $e");
      return [];
    }
  }

  /// Poste un nouveau commentaire
  Future<bool> postComment(String postId, String content) async {
    try {
      final response = await _client.postForm(
        "/posts/$postId/comments",
        {"content": content},
      );
      // On vérifie si l'API renvoie un succès (souvent un ID ou un message)
      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur postComment: $e");
      return false;
    }
  }
}