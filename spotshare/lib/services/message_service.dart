import 'dart:convert';
import '../services/api_client.dart';
import '../models/message.dart'; // Assure-toi que ce modèle existe
import '../models/conversation.dart'; // Assure-toi que ce modèle existe

class MessageService {
  final ApiClient _apiClient = ApiClient();

  // 1. Récupérer ou créer une conversation avec un utilisateur spécifique
  // Cette méthode est cruciale pour le bouton "Message" du profil
  Future<int?> getConversationIdWithUser(int targetUserId) async {
    try {
      // On suppose un endpoint qui cherche une conversation existante avec cet user
      // Si ton backend n'a pas ça, on devra peut-être lister toutes les convos et filtrer
      final response = await _apiClient.get('/messages/conversation/user/$targetUserId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // On retourne l'ID de la conversation
      } else if (response.statusCode == 404) {
        return null; // Pas de conversation, c'est une nouvelle
      }
      return null;
    } catch (e) {
      print("Erreur récupération conversation: $e");
      return null;
    }
  }

  // 2. Récupérer les messages d'une conversation
  Future<List<Message>> getMessages(int conversationId) async {
    try {
      final response = await _apiClient.get('/messages/$conversationId');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Message.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur récupération messages: $e");
      return [];
    }
  }

  // 3. Envoyer un message
  Future<bool> sendMessage(int receiverId, String content) async {
    try {
      final response = await _apiClient.post(
        '/messages/',
        {'receiver_id': receiverId, 'content': content},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Erreur envoi message: $e");
      return false;
    }
  }
}