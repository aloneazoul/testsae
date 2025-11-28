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
  return null;
}