import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:spotshare/services/storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get baseUrl {
    return "https://spotshareapi.fr";
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();

    print("🔵 GET: $url");
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

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

  Future<dynamic> postForm(String endpoint, Map<String, String> data) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final token = await StorageService.getToken();
    final headers = {if (token != null) "Authorization": "Bearer $token"};

    print("🛫 POST FORM: $url \n📦 Data: $data");
    final response = await http.post(url, headers: headers, body: data);
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();

    print("🔴 DELETE: $url");
    final response = await http.delete(url, headers: headers);
    return _processResponse(response);
  }

  // --- MODIFICATION ICI : Ajout du paramètre 'fields' ---
  Future<dynamic> postMultipart(
    String endpoint,
    File file, {
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final token = await StorageService.getToken();

    var request = http.MultipartRequest("POST", url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Ajout des champs textes (caption, lat, lon...)
    if (fields != null) {
      request.fields.addAll(fields);
    }

    var multipartFile = await http.MultipartFile.fromPath('file', file.path);
    request.files.add(multipartFile);

    print("🛫 UPLOAD: $url \n📁 File: ${file.path} \n📝 Fields: $fields");

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      print("❌ Erreur Upload: $e");
      throw Exception("Erreur lors de l'envoi du fichier");
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Non autorisé");
    } else {
      print("❌ Erreur API ${response.statusCode}: ${response.body}");
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }
}
