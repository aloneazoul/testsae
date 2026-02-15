import 'dart:async';
import 'package:spotshare/models/comment_model.dart';
import 'package:spotshare/services/api_client.dart';

class CommentService {
  final ApiClient _client = ApiClient();

  // --- LOGIQUE RADIO (STREAM) ---
  static final StreamController<CommentModel> _commentUpdateController =
      StreamController.broadcast();

  static Stream<CommentModel> get commentUpdates =>
      _commentUpdateController.stream;

  static void notifyCommentUpdated(CommentModel comment) {
    _commentUpdateController.add(comment);
  }

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

  Future<bool> postComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final body = {
        "content": content,
      };
      if (parentCommentId != null) {
        body["parent_comment_id"] = parentCommentId;
      }

      final response = await _client.postForm("/posts/$postId/comments", body);
      return response != null;
    } catch (e) {
      print("Erreur postComment: $e");
      return false;
    }
  }

  // --- LIKE / UNLIKE ---

  Future<bool> likeComment(String commentId) async {
    try {
      final response = await _client.post("/comments/$commentId/like", {});
      return response != null;
    } catch (e) {
      print("Erreur likeComment: $e");
      return false;
    }
  }

  Future<bool> unlikeComment(String commentId) async {
    try {
      final response = await _client.delete("/comments/$commentId/like");
      return response != null;
    } catch (e) {
      print("Erreur unlikeComment: $e");
      return false;
    }
  }
}