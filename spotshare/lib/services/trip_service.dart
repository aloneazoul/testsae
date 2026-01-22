import 'dart:io';
import 'package:spotshare/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:spotshare/services/storage_service.dart';

class TripService {
  final ApiClient _client = ApiClient();

  Future<bool> createTrip(
    Map<String, dynamic> tripData,
    File? bannerFile,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) {
      print("🔴 Erreur: Pas de token");
      return false;
    }

    final url = Uri.parse("${_client.baseUrl}/trips");

    try {
      final request = http.MultipartRequest("POST", url);

      request.headers['Authorization'] = "Bearer $token";

      request.fields['trip_title'] = tripData["trip_title"] ?? "";
      request.fields['is_public'] = (tripData["is_public_flag"] == "Y")
          .toString();

      if (tripData["trip_description"] != null) {
        request.fields['trip_description'] = tripData["trip_description"]!;
      }
      if (tripData["start_date"] != null) {
        request.fields['start_date'] = tripData["start_date"]!;
      }
      if (tripData["end_date"] != null) {
        request.fields['end_date'] = tripData["end_date"]!;
      }

      if (bannerFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("banner_file", bannerFile.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print("📡 Reponse Serveur: $responseBody");

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print("✅ Voyage créé avec fichier");
        return true;
      } else {
        print("❌ Erreur ${streamedResponse.statusCode}: $responseBody");
        return false;
      }
    } catch (e) {
      print("🔴 Erreur réseau Create Trip: $e");
      return false;
    }
  }

  Future<List<dynamic>> getMyTrips() async {
    try {
      final response = await _client.get("/trips/my");

      if (response == null || response is! List) {
        return [];
      }

      return response;
    } catch (e) {
      print("Erreur lors de la récupération des voyages: $e");
      return [];
    }
  }

  Future<bool> deleteTrip(int tripId) async {
    try {
      await _client.delete("/trips/$tripId");
      return true;
    } catch (e) {
      print("Erreur suppression voyage: $e");
      return false;
    }
  }

  Future<List<dynamic>> getTripPosts(int tripId) async {
    try {
      final response = await _client.get("/trips/$tripId/posts");
      if (response != null && response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print("❌ Erreur getTripPosts: $e");
      return [];
    }
  }

  Future<List<dynamic>> getTripsByUser(String userId) async {
    try {
      final response = await _client.get("/trips/user/$userId");
      if (response != null && response is List) return response;
      return [];
    } catch (e) {
      print("❌ Erreur getTripsByUser: $e");
      return [];
    }
  }
}
