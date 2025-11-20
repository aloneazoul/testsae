import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/models/message.dart';

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

  void send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    widget.onSend(widget.conversation.id, text);
    _ctrl.clear();

    setState(() {
      widget.conversation.messages.add(Message(
        id: 'm${Random().nextInt(100000)}',
        text: text,
        time: DateTime.now(),
        fromMe: true,
        read: true,
      ));
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Message m, int index) {
    final convMessages = widget.conversation.messages;
    final isFromMe = m.fromMe;

    // Espacement vertical dynamique
    double verticalPadding = 2;
    if (index > 0) {
      final prev = convMessages[index - 1];
      if (prev.fromMe != m.fromMe) {
        verticalPadding = 12; // plus d'espace quand expéditeur change
      }
    }

    // Vérifie si c'est le dernier message du groupe pour afficher l'avatar
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
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar pour les messages des autres
          if (!isFromMe)
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.conversation.avatarUrl),
                ),
              )
            else
              const SizedBox(width: 44),

          // Bulle de message avec flutter_chat_bubble
          Flexible(
  child: ChatBubble(
    clipper: ChatBubbleClipper2(
      type: isFromMe 
          ? BubbleType.sendBubble
          : BubbleType.receiverBubble,
    ),
    backGroundColor: isFromMe 
        ? dGreen
        : (Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade800 
            : Colors.grey.shade300),
    margin: EdgeInsets.zero,
    alignment: isFromMe ? Alignment.topRight : Alignment.topLeft,
    child: Text(
      m.text,
      style: TextStyle(
        color: isFromMe 
            ? Colors.white 
            : (Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black),
      ),
    ),
  ),
),



          // Avatar pour mes messages
          if (isFromMe)
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.conversation.avatarUrl),
                ),
              )
            else
              const SizedBox(width: 44),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // enlève l’ombre
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(conv.avatarUrl),
            ),
            const SizedBox(width: 12),
            Text(
              conv.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: conv.messages.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final m = conv.messages[index];
                  return Align(
                    alignment: m.fromMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessageBubble(m, index),
                  );
                },
              ),
            ),
            // Zone de saisie type Instagram améliorée
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Container(
    padding: const EdgeInsets.only(left: 16, right: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800 // sombre
          : Colors.grey.shade300, // clair
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white // texte blanc en sombre
                  : Colors.black, // texte noir en clair
            ),
            decoration: InputDecoration(
              hintText: 'Envoyer un message...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => send(),
          ),
        ),
        const SizedBox(width: 4),
        // Bouton envoyer (vert inchangé)
        InkWell(
          onTap: send,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            decoration: BoxDecoration(
              color: dGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ),
      ],
    ),
  ),
)


          ],
        ),
      ),
    );
  }
}
