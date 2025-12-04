import 'dart:async'; // Pour le Timer
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/models/message.dart';
import 'package:spotshare/services/message_service.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;
  final void Function(String conversationId, String text) onSend;

  const ChatPage({super.key, required this.conversation, required this.onSend});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  
  bool _isLoading = true;
  bool _hasSentMessage = false; // Pour signaler le refresh à la liste
  Timer? _timer; // Pour le temps réel

  @override
  void initState() {
    super.initState();
    _initialLoad();

    // ⏱️ TEMPS RÉEL : On vérifie les nouveaux messages toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(silent: true);
    });
  }

  void _initialLoad() async {
    // 1. On dit au serveur "J'ai vu !" pour enlever le gras
    await _messageService.markAsRead(widget.conversation.id);
    // 2. On charge les messages
    await _loadMessages();
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🛑 Très important d'arrêter le timer en sortant
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    final msgs = await _messageService.getMessages(widget.conversation.id);
    
    if (mounted) {
      setState(() {
        // On inverse la liste si l'API renvoie du plus récent au plus vieux
        widget.conversation.messages = msgs.reversed.toList();
        _isLoading = false;
      });
      
      // Si c'est le chargement initial, on scroll tout en bas
      if (!silent) {
        _scrollToBottom();
      } else {
        // Si on reçoit un nouveau message pendant qu'on regarde, on peut scroller doucement
        // (Optionnel : ajouter une logique pour ne scroller que si on est déjà en bas)
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    
    _hasSentMessage = true; // On a écrit, donc la liste devra se mettre à jour

    // Ajout optimiste (pour que ce soit instantané visuellement)
    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      time: DateTime.now(),
      fromMe: true,
      read: false,
    );

    setState(() {
      widget.conversation.messages.add(tempMsg);
    });
    _scrollToBottom();

    await _messageService.sendMessage(widget.conversation.id, text);
  }

  // Gestion du bouton retour
  void _onBack() {
    Navigator.pop(context, _hasSentMessage);
  }

  // Widget Avatar sécurisé (comme sur les autres pages)
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[800],
      // Affiche l'image seulement si l'URL est valide
      foregroundImage: (widget.conversation.avatarUrl.isNotEmpty) 
          ? NetworkImage(widget.conversation.avatarUrl) 
          : null,
      // Sinon icône par défaut
      child: const Icon(Icons.person, size: 20, color: Colors.white54),
    );
  }

  Widget _buildMessageBubble(Message m, int index) {
    final convMessages = widget.conversation.messages;
    final isFromMe = m.fromMe;
    
    double verticalPadding = 2;
    if (index > 0) {
      final prev = convMessages[index - 1];
      if (prev.fromMe != m.fromMe) verticalPadding = 12;
    }

    bool showAvatar = false;
    if (index == convMessages.length - 1) {
      showAvatar = true;
    } else {
      final next = convMessages[index + 1];
      showAvatar = next.fromMe != m.fromMe;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe)
            if (showAvatar)
              Padding(padding: const EdgeInsets.only(right: 8), child: _buildAvatar())
            else
              const SizedBox(width: 44),

          Flexible(
            child: ChatBubble(
              clipper: ChatBubbleClipper2(
                type: isFromMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
              ),
              // Couleurs TikTok / Dark Mode
              backGroundColor: isFromMe 
                  ? dGreen 
                  : const Color(0xFF2A2A2A),
              margin: EdgeInsets.zero,
              alignment: isFromMe ? Alignment.topRight : Alignment.topLeft,
              child: Text(
                m.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope gère le geste "Swipe Back" et le bouton physique Android
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black, // ⚫️ Fond Noir
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          title: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 10),
              Text(
                widget.conversation.name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.conversation.messages.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final m = widget.conversation.messages[index];
                        return Align(
                          alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: _buildMessageBubble(m, index),
                        );
                      },
                    ),
              ),
              // Zone de saisie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A), // Gris foncé
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Envoyer un message...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: send,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, size: 20, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}