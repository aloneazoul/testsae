// lib/services/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:spotshare/services/storage_service.dart';

class ApiClient {
  // Singleton (optionnel mais pratique)
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get baseUrl {
    return Platform.isAndroid
        ? "http://10.0.2.2:8001"
        : "http://127.0.0.1:8001";
  }

  // Méthode pour obtenir les headers avec le token automatiquement
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // GET générique
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();

    print("🔵 GET: $url");
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

  // POST générique
  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();

    print("🛫 POST: $url \n📦 Data: $data");
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
    return _processResponse(response);
  }

  // Gestion centralisée des erreurs
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Si le body est vide, on renvoie null ou un map vide
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // TODO: Gérer la déconnexion automatique ici si le token est expiré
      throw Exception("Non autorisé");
    } else {
      print("❌ Erreur API ${response.statusCode}: ${response.body}");
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }

  // Nouvelle méthode pour envoyer des données "Form Data" (comme un formulaire HTML)
  Future<dynamic> postForm(String endpoint, Map<String, String> data) async {
    final url = Uri.parse("$baseUrl$endpoint");

    // On récupère le token
    final token = await StorageService.getToken();

    // On ne met PAS 'Content-Type': 'application/json' ici !
    final headers = {if (token != null) "Authorization": "Bearer $token"};

    print("🛫 POST FORM: $url \n📦 Data: $data");

    final response = await http.post(
      url,
      headers: headers,
      body: data, // On passe la map directement, sans jsonEncode
    );

    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();

    print("🔴 DELETE: $url");

    final response = await http.delete(url, headers: headers);

    return _processResponse(response);
  }

  // Méthode pour envoyer des fichiers (Multipart Request)
  Future<dynamic> postMultipart(String endpoint, File file) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final token = await StorageService.getToken();

    var request = http.MultipartRequest("POST", url);

    // Ajout du header Authorization
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Préparation du fichier
    // Note: Le champ 'file' correspond au nom du paramètre dans votre API FastAPI : file: UploadFile = File(...)
    var multipartFile = await http.MultipartFile.fromPath('file', file.path);

    request.files.add(multipartFile);

    print("🛫 UPLOAD: $url \n📁 File: ${file.path}");

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      print("❌ Erreur Upload: $e");
      throw Exception("Erreur lors de l'envoi du fichier");
    }
  }
}
