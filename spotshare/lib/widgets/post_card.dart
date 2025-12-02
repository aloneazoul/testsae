import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/pages/Account/profile_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/utils/constants.dart';

final List<Map<String, String>> sampleComments = [
  {'user': 'Emma', 'text': 'Trop cool ton post !', 'avatar': 'https://picsum.photos/seed/emma/50'},
];

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isOwner; 
  final VoidCallback? onDelete;
  // Optionnel : permet de notifier le parent qu'un like a eu lieu
  final Function(bool isLiked, int newCount)? onLikeChanged; 

  const PostCard({
    required this.post, 
    this.isOwner = false, 
    this.onDelete,
    this.onLikeChanged,
    Key? key
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  final PostService _postService = PostService();

  late bool isLiked;
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
    // On initialise avec les données venant de l'API (via le modèle)
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likes;
    commentCount = widget.post.comments;
    
    _pageController = PageController();
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
    final regex = RegExp(r'/(\d+)/(\d+)$');
    final match = regex.firstMatch(url);
    if (match != null) {
      final w = double.parse(match.group(1)!);
      final h = double.parse(match.group(2)!);
      return screenWidth * (h / w); 
    }
    return screenWidth; 
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

  Future<void> _toggleLike() async {
    // 1. Mise à jour visuelle immédiate (Optimistic UI)
    setState(() {
      if (isLiked) {
        isLiked = false;
        likeCount--;
      } else {
        isLiked = true;
        likeCount++;
      }
    });

    // Notifier le parent si besoin
    if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(isLiked, likeCount);
    }

    // 2. Appel API
    bool success;
    if (isLiked) {
      // On vient de passer à TRUE
      success = await _postService.likePost(widget.post.id);
    } else {
      // On vient de passer à FALSE
      success = await _postService.unlikePost(widget.post.id);
    }

    // 3. Si erreur, on annule
    if (!success) {
       if (mounted) {
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
    }
  }

  void handleDoubleTap(TapDownDetails details) {
    if (!isLiked) {
      setState(() {
        heartPosition = details.localPosition;
      });
      _heartController.forward(from: 0);
      _toggleLike();
    } else {
      setState(() {
        heartPosition = details.localPosition;
      });
      _heartController.forward(from: 0);
    }
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
        style: const TextStyle(color: Colors.white),
        children: [
          TextSpan(text: isExpanded ? caption : '$displayText...'),
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
    double firstImageHeight = screenWidth; 
    if (widget.post.imageUrls.isNotEmpty) {
       firstImageHeight = _calculateHeight(widget.post.imageUrls[0], screenWidth);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: widget.post.userId),
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

              if (widget.isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'delete') {
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

        // --- CARROUSEL ---
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


        // --- POINTS INDICATEURS ---
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

        // --- BARRE D'ACTIONS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike, // Appel direct à la fonction toggle
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? dGreen : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 6),
              Text(likeCount.toString(), style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 20),
              
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

        // --- DESCRIPTION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDescription(),
              const SizedBox(height: 4),
              Text(
                'Il y a 4h · Paris, France', 
                style: TextStyle(color: Colors.grey[500], fontSize: 12)
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MODAL COMMENTAIRES (Simulé) ---
  void _showCommentsModal(BuildContext context) {
     // ... (même code qu'avant pour les commentaires)
     // Je l'abrège pour la lisibilité, tu peux garder ton implémentation actuelle
     showModalBottomSheet(context: context, builder: (_) => Container(height: 200, color: dGrey));
  }
}