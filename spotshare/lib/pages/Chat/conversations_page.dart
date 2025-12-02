import 'package:flutter/material.dart';
import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/models/message.dart';
// ✅ Import correct vers le dossier Search
import 'package:spotshare/pages/Search/search_page.dart'; 
import 'chat_page.dart';
import '../../widgets/stories_bar.dart';

class ConversationsPage extends StatelessWidget {
  final List<Conversation> conversations;

  const ConversationsPage({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    // Stories factices
    final stories = [
      {
        "name": "Emma",
        "image": "https://randomuser.me/api/portraits/women/44.jpg"
      },
      {
        "name": "Lucas",
        "image": "https://randomuser.me/api/portraits/men/32.jpg"
      },
      {
        "name": "Sarah",
        "image": "https://randomuser.me/api/portraits/women/65.jpg"
      },
      {
        "name": "Tom",
        "image": "https://randomuser.me/api/portraits/men/48.jpg"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(),
        title: const Text('Messages'),
        elevation: 0,
        // ✅ Bouton Loupe pour la recherche
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Première case = stories
                  return StoriesBar(stories: stories);
                } else {
                  final conv = conversations[index - 1];
                  
                  // Petite sécurité si la conversation est vide
                  final lastMsg = conv.messages.isNotEmpty 
                      ? conv.messages.last 
                      : Message(id: '0', text: 'Nouvelle discussion', time: DateTime.now(), fromMe: false, read: true);

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(conv.avatarUrl),
                    ),
                    title: Text(
                      conv.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, // texte en gras
                      ),
                    ),
                    subtitle: Text(
                      '${lastMsg.text} • il y a 10 h', // message + temps
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 // si dark, blanc légèrement transparent
                            : Colors.black54, // sinon, noir légèrement transparent
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            conversation: conv,
                            onSend: (convId, text) {
                              conv.messages.add(
                                Message(
                                  id: DateTime.now().toString(),
                                  text: text,
                                  time: DateTime.now(),
                                  fromMe: true,
                                  read: true,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}