import 'dart:async'; // 👈 NOUVEAU : Nécessaire pour le Timer
import 'package:flutter/material.dart';
import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/models/message.dart';
import 'package:spotshare/pages/Search/search_page.dart'; 
import 'package:spotshare/services/message_service.dart';
import 'chat_page.dart';
import '../../widgets/stories_bar.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final MessageService _messageService = MessageService();
  List<Conversation> _conversations = [];
  bool _loading = true;
  
  // ⏱️ Variable pour le timer automatique
  Timer? _timer; 

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    
    // Écouteur pour quand on envoie un message NOUS-MÊME (Rafraîchissement immédiat)
    _messageService.refreshNotifier.addListener(_onMessageSentElsewhere);

    // ⏱️ TIMER : Vérifie les nouveaux messages toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // On passe 'false' pour ne pas afficher le rond de chargement à chaque fois
      _fetchConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _messageService.refreshNotifier.removeListener(_onMessageSentElsewhere);
    _timer?.cancel(); // 🛑 TRÈS IMPORTANT : Arrêter le timer quand on quitte la page
    super.dispose();
  }

  void _onMessageSentElsewhere() {
    _fetchConversations();
  }

  // J'ai ajouté un paramètre 'silent' pour éviter que l'écran clignote toutes les 5 sec
  Future<void> _fetchConversations({bool silent = false}) async {
    // Si c'est silencieux, on ne met pas _loading à true
    if (!silent) {
      if (mounted) setState(() => _loading = true);
    }

    final res = await _messageService.getMyConversations();
    
    if (mounted) {
      setState(() {
        _conversations = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = [
      {"name": "Emma", "image": "https://randomuser.me/api/portraits/women/44.jpg"},
      {"name": "Lucas", "image": "https://randomuser.me/api/portraits/men/32.jpg"},
      {"name": "Sarah", "image": "https://randomuser.me/api/portraits/women/65.jpg"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Boîte de réception',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w700, 
            color: Colors.white
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: () => _fetchConversations(),
              child: ListView.builder(
                itemCount: _conversations.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      color: Colors.black,
                      child: Theme(
                        data: Theme.of(context).copyWith(brightness: Brightness.dark),
                        child: StoriesBar(stories: stories),
                      ),
                    );
                  } else {
                    final conv = _conversations[index - 1];
                    final lastMsg = conv.messages.isNotEmpty 
                        ? conv.messages.first 
                        : Message(id: '0', text: '', time: DateTime.now(), fromMe: false, read: true);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[800],
                        foregroundImage: (conv.avatarUrl.isNotEmpty) 
                            ? NetworkImage(conv.avatarUrl) 
                            : null,
                        child: const Icon(Icons.person, color: Colors.white54, size: 28),
                      ),
                      title: Text(
                        conv.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          lastMsg.fromMe ? "Vous: ${lastMsg.text}" : lastMsg.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (lastMsg.read == false && !lastMsg.fromMe) 
                                ? Colors.white 
                                : Colors.grey[500],
                            fontWeight: (lastMsg.read == false && !lastMsg.fromMe) 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${lastMsg.time.hour}:${lastMsg.time.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          // Petit point bleu si nouveau message non lu
                          if (lastMsg.read == false && !lastMsg.fromMe)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent, // Ou ta couleur dGreen
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      onTap: () async {
                        // On navigue vers le chat
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              conversation: conv,
                              onSend: (convId, text) {},
                            ),
                          ),
                        );
                        // On refresh au retour
                        _fetchConversations();
                      },
                    );
                  }
                },
              ),
            ),
    );
  }
}