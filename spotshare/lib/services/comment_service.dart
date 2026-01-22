import 'package:spotshare/services/api_client.dart';
import 'package:spotshare/models/comment_model.dart';

class CommentService {
  final ApiClient _client = ApiClient();

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

  Future<bool> postComment(String postId, String content) async {
    try {
      final response = await _client.postForm("/posts/$postId/comments", {
        "content": content,
      });
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
