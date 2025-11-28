import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/pages/Feed/profile/profile_page.dart'; // Assure-toi que le chemin est bon selon ton projet
import 'package:spotshare/utils/constants.dart';

final List<Map<String, String>> sampleComments = [
  {'user': 'Emma', 'text': 'Trop cool ton post !', 'avatar': 'https://picsum.photos/seed/emma/50'},
  {'user': 'Lucas', 'text': 'J’adore 😍', 'avatar': 'https://picsum.photos/seed/lucas/50'},
  {'user': 'Zoé', 'text': 'Super journée !', 'avatar': 'https://picsum.photos/seed/zoe/50'},
  {'user': 'Léa', 'text': 'Top !', 'avatar': 'https://picsum.photos/seed/lea/50'},
  {'user': 'Ronan', 'text': 'Impressionnant !', 'avatar': 'https://picsum.photos/seed/ronan/50'},
];

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isOwner; // <--- NOUVEAU : Définit si l'utilisateur est le créateur
  final VoidCallback? onDelete; // <--- NOUVEAU : Action de suppression

  const PostCard({
    required this.post, 
    this.isOwner = false, 
    this.onDelete,
    Key? key
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  bool isLiked = false;
  late int likeCount;
  late int commentCount;
  bool isExpanded = false;
  int currentPage = 0;
  late final PageController _pageController;

  late List<double> imageHeights;

  Offset? heartPosition;
  late final AnimationController _heartController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _moveAnimation;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likes;
    commentCount = widget.post.comments;
    _pageController = PageController();
    
    // Initialisation par défaut, sera mis à jour via addPostFrameCallback
    imageHeights = List.filled(widget.post.imageUrls.length, 250);

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );

    _moveAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5),
    ).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateImageHeights());
  }

  double _calculateHeight(String url, double screenWidth) {
    // Tente d'extraire la taille depuis l'URL (ex: /600/400) pour placeholder
    // Sinon on garde un ratio par défaut
    final regex = RegExp(r'/(\d+)/(\d+)$');
    final match = regex.firstMatch(url);
    if (match != null) {
      final w = double.parse(match.group(1)!);
      final h = double.parse(match.group(2)!);
      return screenWidth * (h / w); 
    }
    return screenWidth; // fallback carré
  }

  void _updateImageHeights() {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      imageHeights = widget.post.imageUrls
          .map((url) => _calculateHeight(url, screenWidth))
          .toList();
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void handleDoubleTap(TapDownDetails details) {
    if (!isLiked) {
      setState(() {
        isLiked = true;
        likeCount++;
        heartPosition = details.localPosition;
      });
      _heartController.forward(from: 0);
    } else {
      setState(() {
        heartPosition = details.localPosition;
      });
      _heartController.forward(from: 0);
    }
  }

  void handleLikeButton() {
    setState(() {
      if (isLiked) {
        isLiked = false;
        likeCount--;
      } else {
        isLiked = true;
        likeCount++;
      }
    });
  }

  Widget buildDescription() {
    final caption = widget.post.caption;
    if (caption.isEmpty) return const SizedBox.shrink();

    if (caption.length <= 60) {
      return Text(caption, style: const TextStyle(color: Colors.white));
    }

    final displayText = isExpanded ? caption : caption.substring(0, 40);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white, // Assuré blanc pour le thème dark
        ),
        children: [
          TextSpan(
            text: isExpanded ? caption : '$displayText...',
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Text(
                isExpanded ? ' moins' : ' plus',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcul de la hauteur de la première image pour fixer la taille du PageView
    double firstImageHeight = screenWidth; 
    if (widget.post.imageUrls.isNotEmpty) {
       firstImageHeight = _calculateHeight(widget.post.imageUrls[0], screenWidth);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER : Profil + Menu Options (si Owner) ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Partie Gauche : Avatar et Pseudo
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Note : ProfilePage nécessite peut-être d'autres paramètres selon ta modif
                      builder: (_) => ProfilePage(userName: widget.post.userName),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: (widget.post.profileImageUrl.isNotEmpty) 
                        ? NetworkImage(widget.post.profileImageUrl)
                        : null,
                      backgroundColor: Colors.grey[800],
                      child: widget.post.profileImageUrl.isEmpty 
                        ? const Icon(Icons.person, color: Colors.white) 
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Partie Droite : Menu 3 points (Seulement si Owner)
              if (widget.isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'delete') {
                      // Appel du callback de suppression
                      if (widget.onDelete != null) widget.onDelete!();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Modifier la légende', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // --- CARROUSEL D'IMAGES ---
        if (widget.post.imageUrls.isNotEmpty)
          SizedBox(
            height: firstImageHeight,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.post.imageUrls.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (context, index) {
                final url = widget.post.imageUrls[index];

                return GestureDetector(
                  onDoubleTapDown: handleDoubleTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: firstImageHeight,
                        color: Colors.black,
                        child: Image.network(
                          url,
                          width: double.infinity,
                          height: firstImageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white)),
                        ),
                      ),
                      // Animation du coeur
                      if (heartPosition != null && currentPage == index)
                        AnimatedBuilder(
                          animation: _heartController,
                          builder: (_, child) {
                            final offset = _moveAnimation.value;
                            final scale = _scaleAnimation.value;
                            return Positioned(
                              left: heartPosition!.dx - 40,
                              top: heartPosition!.dy - 40,
                              child: Transform.translate(
                                offset: offset * 100,
                                child: Transform.scale(
                                  scale: scale,
                                  child: Icon(
                                    Icons.favorite,
                                    color: dGreen.withOpacity(0.8),
                                    size: 80,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),


        // --- POINTS INDICATEURS (si plusieurs images) ---
        if (widget.post.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.post.imageUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: currentPage == index ? 8 : 6,
                  height: currentPage == index ? 8 : 6,
                  decoration: BoxDecoration(
                    color: currentPage == index ? dGreen : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),

        // --- BARRE D'ACTIONS (Likes, Coms) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: handleLikeButton,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? dGreen : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 6),
              Text(likeCount.toString(), style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 20),
              
              // Bouton Commentaires
              GestureDetector(
                onTap: () {
                  _showCommentsModal(context);
                },
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 6),
              Text(commentCount.toString(), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),

        // --- DESCRIPTION + INFO ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDescription(),
              const SizedBox(height: 4),
              Text(
                // Affichage simple de la date (à améliorer avec timeago si besoin)
                'Il y a 4h · Paris, France', 
                style: TextStyle(color: Colors.grey[500], fontSize: 12)
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MODAL COMMENTAIRES (Extrait pour lisibilité) ---
  void _showCommentsModal(BuildContext context) {
    final TextEditingController _ctrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: dGrey, // Assure-toi que cette couleur est définie dans constants.dart
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // Barre de drag
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Commentaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Divider(color: Colors.grey[700], height: 1),

                // Liste des commentaires
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: commentCount > sampleComments.length ? sampleComments.length : commentCount, // Simu
                    itemBuilder: (context, index) {
                      // Protection index si commentCount > sample
                      final safeIndex = index % sampleComments.length;
                      final comment = sampleComments[safeIndex];
                      
                      bool isCommentLiked = false;
                      int commentLikes = 0;

                      return StatefulBuilder(
                        builder: (context, setStateSB) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(comment['avatar']!),
                                radius: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment['user']!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '3h',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment['text']!, style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Répondre',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setStateSB(() {
                                        isCommentLiked = !isCommentLiked;
                                        commentLikes += isCommentLiked ? 1 : -1;
                                      });
                                    },
                                    child: Icon(
                                      isCommentLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isCommentLiked ? dGreen : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                  if (commentLikes > 0)
                                    Text(
                                      commentLikes.toString(),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Zone de saisie
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: const BoxDecoration(
                    color: dGrey,
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        // Image utilisateur connecté (placeholder)
                        backgroundImage: NetworkImage('https://picsum.photos/seed/myprofile/50'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Ajouter un commentaire...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          if (_ctrl.text.isNotEmpty) _ctrl.clear();
                        },
                        child: CircleAvatar(
                          backgroundColor: dGreen,
                          radius: 20,
                          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}