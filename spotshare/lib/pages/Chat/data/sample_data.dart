import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/models/message.dart';

List<Conversation> sampleConversations() {
  return [
    Conversation(
      id: 'c1',
      name: 'Léna',
      avatarUrl: 'https://picsum.photos/seed/1/200/200',
      messages: [
        Message(id: 'm1', text: 'Salut ! T\'as vu ma nouvelle vidéo ?', time: DateTime.now().subtract(const Duration(minutes: 120)), fromMe: false),
        Message(id: 'm2', text: 'Oui, superbe montage 🔥', time: DateTime.now().subtract(const Duration(minutes: 115)), fromMe: true, read: true),
      ],
    ),
    Conversation(
      id: 'c2',
      name: 'Marc',
      avatarUrl: 'https://picsum.photos/seed/2/200/200',
      messages: [
        Message(id: 'm1', text: 'On se voit ce soir ?', time: DateTime.now().subtract(const Duration(hours: 5)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c3',
      name: 'Emma',
      avatarUrl: 'https://picsum.photos/seed/3/200/200',
      messages: [
        Message(id: 'm1', text: 'Tu viens au ciné demain ?', time: DateTime.now().subtract(const Duration(hours: 2)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c4',
      name: 'Lucas',
      avatarUrl: 'https://picsum.photos/seed/4/200/200',
      messages: [
        Message(id: 'm1', text: 'J’ai fini le projet !', time: DateTime.now().subtract(const Duration(minutes: 45)), fromMe: true, read: true),
        Message(id: 'm2', text: 'Super, bravo !', time: DateTime.now().subtract(const Duration(minutes: 40)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c5',
      name: 'Sarah',
      avatarUrl: 'https://picsum.photos/seed/5/200/200',
      messages: [
        Message(id: 'm1', text: 'Tu veux prendre un café ?', time: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c6',
      name: 'Tom',
      avatarUrl: 'https://picsum.photos/seed/6/200/200',
      messages: [
        Message(id: 'm1', text: 'Ok pour demain !', time: DateTime.now().subtract(const Duration(minutes: 10)), fromMe: true, read: true),
      ],
    ),
    Conversation(
      id: 'c7',
      name: 'Alice',
      avatarUrl: 'https://picsum.photos/seed/7/200/200',
      messages: [
        Message(id: 'm1', text: 'Tu as fini ton devoir ?', time: DateTime.now().subtract(const Duration(hours: 3)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c8',
      name: 'Nathan',
      avatarUrl: 'https://picsum.photos/seed/8/200/200',
      messages: [
        Message(id: 'm1', text: 'Aller au foot ce week-end ?', time: DateTime.now().subtract(const Duration(hours: 6)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c9',
      name: 'Chloé',
      avatarUrl: 'https://picsum.photos/seed/9/200/200',
      messages: [
        Message(id: 'm1', text: 'J’ai trouvé un super resto !', time: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c10',
      name: 'Julien',
      avatarUrl: 'https://picsum.photos/seed/10/200/200',
      messages: [
        Message(id: 'm1', text: 'Ça marche pour demain', time: DateTime.now().subtract(const Duration(minutes: 90)), fromMe: true, read: true),
      ],
    ),
    Conversation(
      id: 'c11',
      name: 'Manon',
      avatarUrl: 'https://picsum.photos/seed/11/200/200',
      messages: [
        Message(id: 'm1', text: 'Tu as vu ce film ?', time: DateTime.now().subtract(const Duration(hours: 7)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c12',
      name: 'Maxime',
      avatarUrl: 'https://picsum.photos/seed/12/200/200',
      messages: [
        Message(id: 'm1', text: 'Je t’envoie le fichier demain', time: DateTime.now().subtract(const Duration(minutes: 55)), fromMe: true, read: true),
      ],
    ),
    Conversation(
      id: 'c13',
      name: 'Lola',
      avatarUrl: 'https://picsum.photos/seed/13/200/200',
      messages: [
        Message(id: 'm1', text: 'On fait une soirée samedi ?', time: DateTime.now().subtract(const Duration(hours: 8, minutes: 20)), fromMe: false),
      ],
    ),
    Conversation(
      id: 'c14',
      name: 'Antoine',
      avatarUrl: 'https://picsum.photos/seed/14/200/200',
      messages: [
        Message(id: 'm1', text: 'Oui pas de problème !', time: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)), fromMe: true, read: true),
      ],
    ),
    Conversation(
      id: 'c15',
      name: 'Camille',
      avatarUrl: 'https://picsum.photos/seed/15/200/200',
      messages: [
        Message(id: 'm1', text: 'Je t’appelle ce soir', time: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)), fromMe: false),
      ],
    ),
  ];
}
