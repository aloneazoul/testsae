import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/api_client.dart';

ApiClient apiClient = ApiClient();

Future<Map<String, dynamic>?> getMyProfile() async {
  final token = await StorageService.getToken();
  if (token == null) return null;

  final url = "${apiClient.baseUrl}/me";

  try {
    print("🔵 Récupération profil : $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    print("🔴 Erreur réseau Profil : $e");
  }
  return null;
}

Future<List<dynamic>> searchUsers(String query) async {
  final token = await StorageService.getToken();

  final url = "${apiClient.baseUrl}/search/users?query=$query";

  try {
    print("🔵 Search Users : $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur API search: ${response.statusCode} ${response.body}");
    }
  } catch (e) {
    print("🔴 Erreur réseau search : $e");
  }
  return [];
}

Future<Map<String, dynamic>?> getUserById(String userId) async {
  final token = await StorageService.getToken();
  final url = "${apiClient.baseUrl}/users/$userId";

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
    print("🔴 Erreur getUserById : $e");
  }
  return null;
}

Future<bool> followUser(String targetUserId) async {
  final token = await StorageService.getToken();
  final url = "${apiClient.baseUrl}/follow/$targetUserId";

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Erreur follow: $e");
    return false;
  }
}

Future<bool> unfollowUser(String targetUserId) async {
  final token = await StorageService.getToken();
  final url = "${apiClient.baseUrl}/follow/$targetUserId";

  try {
    final response = await http.delete(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    return response.statusCode == 200;
  } catch (e) {
    print("Erreur unfollow: $e");
    return false;
  }
}
