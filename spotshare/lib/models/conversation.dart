import 'message.dart';

class Conversation {
  final String id;
  final String name;
  final String avatarUrl;
  List<Message> messages;

  Conversation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.messages,
  });
}
