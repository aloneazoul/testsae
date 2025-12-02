// lib/services/trip_service.dart
import 'dart:io';
import 'package:spotshare/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:spotshare/services/storage_service.dart';

class TripService {
  final ApiClient _client = ApiClient();

  // CRÉATION DE VOYAGE (Finalisée avec gestion de fichier)
  Future<bool> createTrip(Map<String, dynamic> tripData, File? bannerFile) async {
    final token = await StorageService.getToken(); 
    if (token == null) {
        print("🔴 Erreur: Pas de token");
        return false;
    }

    // Le format MultipartRequest gère l'envoi des champs texte ET des fichiers.
    final url = Uri.parse("${_client.baseUrl}/trips");
    
    try {
      final request = http.MultipartRequest("POST", url);

      // Ajout du token d'authentification dans les headers
      request.headers['Authorization'] = "Bearer $token";

      // 1. Ajout des champs texte (Form Data)
      // Mappage des clés Flutter aux arguments FastAPI
      request.fields['trip_title'] = tripData["trip_title"] ?? "";
      request.fields['is_public'] = (tripData["is_public_flag"] == "Y").toString(); 
      
      // Champs optionnels
      if (tripData["trip_description"] != null) {
        request.fields['trip_description'] = tripData["trip_description"]!;
      }
      if (tripData["start_date"] != null) {
        request.fields['start_date'] = tripData["start_date"]!;
      }
      if (tripData["end_date"] != null) {
        request.fields['end_date'] = tripData["end_date"]!;
      }
      
      // 2. Ajout du fichier de bannière (bannerFile)
      // On utilise 'banner_file' comme nom de champ, qui doit correspondre à ce que FastAPI attend.
      if (bannerFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("banner_file", bannerFile.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print("📡 Reponse Serveur: $responseBody");

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
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
      // On appelle la route GET définie dans ton backend Python (@router.get("/trips/my"))
      final response = await _client.get("/trips/my");
      
      // Si la réponse est null ou n'est pas une liste, on renvoie une liste vide
      if (response == null || response is! List) {
        return [];
      }
      
      return response;
    } catch (e) {
      print("Erreur lors de la récupération des voyages: $e");
      return [];
    }
  }

  // NOUVEAU : Supprimer un voyage
  Future<bool> deleteTrip(int tripId) async {
    try {
      // DELETE /trips/{trip_id}
      await _client.delete("/trips/$tripId"); 
      // Note: Il faudra ajouter la méthode delete() dans ApiClient si elle n'existe pas,
      // ou utiliser _client.deleteTrip si tu l'as nommée ainsi.
      // Si tu n'as pas de méthode delete générique, dis-le moi, mais voici le standard :
      return true;
    } catch (e) {
      print("Erreur suppression voyage: $e");
      return false;
    }
  }

  // Récupérer les posts d'un voyage spécifique
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
  
// Récupérer les voyages d'un utilisateur spécifique
Future<List<dynamic>> getTripsByUser(String userId) async {
  try {
    // Vérifie la route backend (ex: /trips/user/{id})
    final response = await _client.get("/trips/user/$userId"); 
    if (response != null && response is List) return response;
    return [];
  } catch (e) {
    print("❌ Erreur getTripsByUser: $e");
    return [];
  }
}
}