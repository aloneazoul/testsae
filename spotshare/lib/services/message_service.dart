import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final ApiClient _apiClient = ApiClient();

  final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  String _fixAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    String base = _apiClient.baseUrl;
    if (!url.startsWith('/')) {
      return "$base/$url";
    }
    return "$base$url";
  }

  Future<List<Conversation>> getMyConversations() async {
    try {
      final List<dynamic> body = await _apiClient.get(
        '/messages/conversations',
      );

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
              fromMe:
                  item['sender_id'] != int.parse(item['user_id'].toString()),
              read: item['is_read_flag'] == 'Y',
            ),
          ],
        );
      }).toList();
    } catch (e) {
      print("Erreur getMyConversations: $e");
      return [];
    }
  }

  Future<List<Message>> getMessages(String otherUserId) async {
    try {
      final List<dynamic> body = await _apiClient.get(
        '/messages/private/$otherUserId',
      );

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

  Future<bool> sendMessage(String receiverId, String content) async {
    try {
      await _apiClient.postForm('/messages/private', {
        'receiver_id': receiverId,
        'content': content,
      });

      refreshNotifier.value = !refreshNotifier.value;

      return true;
    } catch (e) {
      print("Erreur envoi message: $e");
      return false;
    }
  }

  Future<void> markAsRead(String otherUserId) async {
    try {
      await _apiClient.post('/messages/private/read_all/$otherUserId', {});

      refreshNotifier.value = !refreshNotifier.value;
    } catch (e) {
      print("Erreur markAsRead: $e");
    }
  }
}
