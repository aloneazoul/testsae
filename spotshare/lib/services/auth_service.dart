import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/api_client.dart';
import 'dart:io';

ApiClient apiClient = new ApiClient();

Future<bool> loginToServer(String email, String password) async {
  final response = await http.post(
    Uri.parse("${apiClient.baseUrl}/login"),
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
  final url = Uri.parse("${apiClient.baseUrl}/register");

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
