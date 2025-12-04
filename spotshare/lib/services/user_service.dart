import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/api_client.dart';

// Instance globale du client API
ApiClient apiClient = ApiClient();

// ==================================================
// 1. RÉCUPÉRER MON PROFIL
// ==================================================
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

// Recherche d'utilisateurs (si query est vide "", renvoie la liste par défaut)
Future<List<dynamic>> searchUsers(String query) async {
  final token = await StorageService.getToken();

  // On passe le paramètre query dans l'URL
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

// ==================================================
// 3. RÉCUPÉRER UN PROFIL PAR ID (PUBLIC)
// ==================================================
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

// ==================================================
// 4. SUIVRE UN UTILISATEUR
// ==================================================
Future<bool> followUser(String targetUserId) async {
  final token = await StorageService.getToken();
  // CORRECTION : /follow/ au lieu de /followers/
  final url = "${apiClient.baseUrl}/follow/$targetUserId";

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
    // 200 = succès, 400 = déjà suivi ou erreur
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print("Erreur follow: $e");
    return false;
  }
}

// ==================================================
// 5. NE PLUS SUIVRE (UNFOLLOW)
// ==================================================
Future<bool> unfollowUser(String targetUserId) async {
  final token = await StorageService.getToken();
  // CORRECTION : /follow/ au lieu de /followers/
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
