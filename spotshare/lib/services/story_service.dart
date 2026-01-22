import 'package:spotshare/services/api_client.dart';

class StoryService {
  final ApiClient _client = ApiClient();

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

  Future<bool> postStory(String filePath) async {
    return true;
  }
}
