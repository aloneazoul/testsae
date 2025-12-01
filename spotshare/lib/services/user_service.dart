import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/api_client.dart';

ApiClient apiClient = new ApiClient();

// Récupérer mon profil
Future<Map<String, dynamic>?> getMyProfile() async {
  final token = await StorageService.getToken();
  if (token == null) return null;

  final url = "${apiClient.baseUrl}/me";

  try {
    print("🔵 Récupération profil : $url, $token");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("   Réponse Profil: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    print("🔴 Erreur réseau Profil : $e");
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