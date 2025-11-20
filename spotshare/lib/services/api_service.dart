import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> loginToServer(String email, String password) async {
  final response = await http.post(
    Uri.parse("http://10.0.2.2:8001/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['access_token'] != null) {
      print('Connexion réussie. Token: ${data['access_token']}');
      return true;
    }
  }
  return false;
}

Future<bool> CreateUser(String email, String pseudo, String password) async {
  final response = await http.post(
    Uri.parse("http://10.0.2.2:8001/register"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "pseudo": pseudo, "password": password}),
  );

  if (response.statusCode == 200) {
    print('Création de compte réussie.');
    return true;
  }
  return false;
}
