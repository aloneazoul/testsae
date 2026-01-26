import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotshare/services/storage_service.dart';
import 'dart:io';

String getBaseUrl() {
  return "http://127.0.0.1:8001";
}

Future<bool> loginToServer(String email, String password) async {
  final response = await http.post(
    Uri.parse("${getBaseUrl()}/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['access_token'] != null) {
      await StorageService.saveToken(data['access_token']);
      return true;
    }
  }
  return false;
}

Future<bool> CreateUser(
  String email,
  String pseudo,
  String password,
  File? imageFile,
  String gender,
  String? bio,
  String phoneNumber,
  String birthDate,
  String isPrivate,
) async {
  final url = Uri.parse("${getBaseUrl()}/register");

  try {
    final request = http.MultipartRequest("POST", url);

    request.fields['email'] = email;
    request.fields['pseudo'] = pseudo;
    request.fields['password'] = password;
    request.fields['gender'] = gender;
    request.fields['phone'] = phoneNumber;
    request.fields['birthDate'] = birthDate;
    request.fields['private'] = isPrivate;

    if (bio != null) {
      request.fields['bio'] = bio;
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("imgFile", imageFile.path),
      );
    }

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    print("📡 Reponse Serveur: $responseBody");

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      print("✅ Utilisateur créé");
      return true;
    } else {
      print("❌ Erreur ${streamed.statusCode}: $responseBody");
      return false;
    }
  } catch (e) {
    print("🔴 Erreur réseau: $e");
    return false;
  }
}

Future<Map<String, dynamic>?> getMyProfile() async {
  final token = await StorageService.getToken();
  if (token == null) return null;

  final url = "${getBaseUrl()}/me";

  try {
    print("🔵 Récupération profil : $url");
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
