import 'package:flutter/foundation.dart'; // Nécessaire pour ValueNotifier
import '../services/api_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessageService {
  // 1. SINGLETON : Une seule instance partagée pour toute l'appli
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final ApiClient _apiClient = ApiClient();

  // 2. NOTIFIER : Un signal que les autres pages peuvent écouter
  // On change cette valeur pour dire "Hé ! Il y a du nouveau !"
  final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  // Helper pour l'avatar
  String _fixAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    String base = _apiClient.baseUrl; 
    if (!url.startsWith('/')) {
      return "$base/$url";
    }
    return "$base$url";
  }

  // Récupérer la liste des conversations
  Future<List<Conversation>> getMyConversations() async {
    try {
      final List<dynamic> body = await _apiClient.get('/messages/conversations');

      return body.map((item) {
        return Conversation(
          id: item['user_id'].toString(),
          name: item['username'] ?? 'Inconnu',
          avatarUrl: _fixAvatarUrl(item['profile_picture']), 
          messages: [
            Message(
              id: 'preview',
              text: item['content'] ?? 'Image/Média',
              time: DateTime.parse(item['sent_at']),
              fromMe: item['sender_id'] != int.parse(item['user_id'].toString()),
              read: item['is_read_flag'] == 'Y',
            )
          ],
        );
      }).toList();
    } catch (e) {
      print("Erreur getMyConversations: $e");
      return [];
    }
  }

  // Récupérer l'historique d'une conversation
  Future<List<Message>> getMessages(String otherUserId) async {
    try {
      final List<dynamic> body = await _apiClient.get('/messages/private/$otherUserId');

      return body.map((item) {
        return Message(
          id: item['private_message_id'].toString(),
          text: item['content'] ?? '',
          time: DateTime.parse(item['sent_at']),
          fromMe: item['sender_id'].toString() != otherUserId, 
          read: item['is_read_flag'] == 'Y',
        );
      }).toList();
    } catch (e) {
      print("Erreur récupération messages: $e");
      return [];
    }
  }

  // Envoyer un message
  Future<bool> sendMessage(String receiverId, String content) async {
    try {
      await _apiClient.postForm(
        '/messages/private',
        {
          'receiver_id': receiverId,
          'content': content
        },
      );
      
      // 3. SIGNALER LE CHANGEMENT
      // On inverse la valeur pour déclencher les écouteurs (ConversationsPage)
      refreshNotifier.value = !refreshNotifier.value; 
      
      return true;
    } catch (e) {
      print("Erreur envoi message: $e");
      return false;
    }
  }

  // 4. Marquer toute la conversation comme lue
  Future<void> markAsRead(String otherUserId) async {
    try {
      // On appelle la nouvelle route. Le body {} est vide car tout est dans l'URL.
      await _apiClient.post('/messages/private/read_all/$otherUserId', {});
      
      // On signale le changement pour que la liste des conversations se mette à jour au retour
      refreshNotifier.value = !refreshNotifier.value; 
    } catch (e) {
      print("Erreur markAsRead: $e");
    }
  }
}