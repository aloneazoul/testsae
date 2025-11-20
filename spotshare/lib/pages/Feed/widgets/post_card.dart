import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import '../profile/profile_page.dart';
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

  const PostCard({required this.post, Key? key}) : super(key: key);

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
    imageHeights = List.filled(widget.post.imageUrls.length, 250);

    _heartController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );

    _moveAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, 1.5),
    ).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateImageHeights());
  }

  double _calculateHeight(String url, double screenWidth) {
    // Extraire la largeur et hauteur depuis l'URL (ex: /600/400)
    final regex = RegExp(r'/(\d+)/(\d+)$');
    final match = regex.firstMatch(url);
    if (match != null) {
      final w = double.parse(match.group(1)!);
      final h = double.parse(match.group(2)!);
      return screenWidth * (h / w); // ratio réel
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
    if (caption.length <= 60) return Text(caption);

    final displayText = isExpanded ? caption : caption.substring(0, 40);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground, // couleur principale texte
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
final firstImageHeight = _calculateHeight(widget.post.imageUrls[0], screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profil du post
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userName: widget.post.userName),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.transparent,
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(widget.post.profileImageUrl)),
                SizedBox(width: 8),
                Text(widget.post.userName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        // Carrousel d'images
        // Dans le build() :

Container(
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
              color: Colors.black, // bandes noires si image plus petite
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(
                  url,
                  width: double.infinity,
                  height: firstImageHeight,
                  fit: BoxFit.cover, // rogne si plus grand, bandes noires si plus petit
                ),
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


        // Points du carrousel
        if (widget.post.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.post.imageUrls.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
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

        // Likes & commentaires
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: handleLikeButton,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  
                  color: isLiked 
                    ? dGreen  // vert
                    : Theme.of(context).colorScheme.onBackground, // texte
                ),
              ),
              SizedBox(width: 4),
              Text(likeCount.toString()),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () {
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
                          decoration: BoxDecoration(
                            color: dGrey,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 5,
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    'Commentaires',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Divider(color: Colors.grey[700]),

                                Expanded(
                                  child: ListView.builder(
                                    itemCount: commentCount,
                                    itemBuilder: (context, index) {
                                      final comment = sampleComments[index % sampleComments.length];
                                      bool isCommentLiked = false;
                                      int commentLikes = 0;

                                      return StatefulBuilder(
                                        builder: (context, setStateSB) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(comment['avatar']!),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          comment['user']!,
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          '3h',
                                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(comment['text']!),
                                                    TextButton(
                                                      onPressed: () {},
                                                      style: TextButton.styleFrom(
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: Size(50, 20),
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                      child: Text(
                                                        'Répondre',
                                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                      ),
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
                                                      color: isCommentLiked 
                                                        ? dGreen  // couleur principale du thème
                                                        : Theme.of(context).colorScheme.onBackground,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  if (commentLikes > 0)
                                                    Text(
                                                      commentLikes.toString(),
                                                      style: TextStyle( fontSize: 12),
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

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage('https://picsum.photos/seed/myprofile/50'),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.only(left: 16, right: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _ctrl,
                                                  textCapitalization: TextCapitalization.sentences,
                                                  decoration: InputDecoration(
                                                    hintText: 'Envoyer un commentaire...',
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  if (_ctrl.text.isNotEmpty) _ctrl.clear();
                                                },
                                                borderRadius: BorderRadius.circular(30),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: dGreen,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: const Icon(Icons.arrow_upward, size: 20),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Icon(Icons.comment),
              ),
              SizedBox(width: 4),
              Text(commentCount.toString()),
            ],
          ),
        ),

        // Caption + heure + lieu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDescription(),
              SizedBox(height: 4),
              Text('Il y a 4h · Paris, France',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
