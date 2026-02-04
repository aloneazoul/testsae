import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/models/comment_model.dart';
import 'package:spotshare/models/story_model.dart'; // IMPÉRATIF POUR CORRIGER L'ERREUR
import 'package:spotshare/pages/Account/profile_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/comment_service.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Feed/story_player_page.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isOwner;
  final VoidCallback? onDelete;
  final Function(PostModel updatedPost)? onPostUpdated;
  final double textSize;
  
  // CORRECTION : On attend un objet UserStoryGroup typé, plus une Map
  final UserStoryGroup? storyGroup;

  const PostCard({
    required this.post,
    this.isOwner = false,
    this.onDelete,
    this.textSize = 12,
    this.onPostUpdated,
    this.storyGroup,
    Key? key,
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
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likes;
    commentCount = widget.post.comments;

    _pageController = PageController();
    
    imageHeights = List.filled(
      widget.post.imageUrls.isNotEmpty ? widget.post.imageUrls.length : 1,
      350.0,
    );

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
    ).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateImageHeights());
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      setState(() {
        isLiked = widget.post.isLiked;
        likeCount = widget.post.likes;
        commentCount = widget.post.comments;
      });
    }
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
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    if (widget.post.imageUrls.isNotEmpty) {
      setState(() {
        imageHeights = widget.post.imageUrls
            .map((url) => _calculateHeight(url, screenWidth))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final bool wasLiked = isLiked;
    final int wasLikeCount = likeCount;

    setState(() {
      if (wasLiked) {
        isLiked = false;
        likeCount--;
      } else {
        isLiked = true;
        likeCount++;
      }
    });

    final updatedPostOptimistic = widget.post.copyWith(
      isLiked: isLiked,
      likes: likeCount,
    );

    PostService.notifyPostUpdated(updatedPostOptimistic);

    if (widget.onPostUpdated != null) {
      widget.onPostUpdated!(updatedPostOptimistic);
    }

    bool success;
    if (isLiked) {
      success = await _postService.likePost(widget.post.id);
    } else {
      success = await _postService.unlikePost(widget.post.id);
    }

    if (!success && mounted) {
      setState(() {
        isLiked = wasLiked;
        likeCount = wasLikeCount;
      });
      final revertedPost = widget.post.copyWith(
        isLiked: wasLiked,
        likes: wasLikeCount,
      );
      PostService.notifyPostUpdated(revertedPost);
      if (widget.onPostUpdated != null) widget.onPostUpdated!(revertedPost);
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
    final double size = widget.textSize;
    final caption = widget.post.caption;
    if (caption.isEmpty) return const SizedBox.shrink();

    if (caption.length <= 60) {
      return Text(
        caption,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          decoration: TextDecoration.none,
        ),
      );
    }
    final displayText = isExpanded ? caption : caption.substring(0, 40);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          decoration: TextDecoration.none,
        ),
        children: [
          TextSpan(text: isExpanded ? caption : '$displayText...'),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Text(
                isExpanded ? " moins" : " plus",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: size,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return "${date.day}-${date.month}";
    if (diff.inDays >= 1) return "${diff.inDays}j";
    if (diff.inHours >= 1) return "${diff.inHours}h";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m";
    return "À l'instant";
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
    );
  }

  // --- CORRECTION : Utilisation des propriétés typées de UserStoryGroup ---
  void _onAvatarTap() {
    // Vérification propre avec le modèle
    if (widget.storyGroup != null && widget.storyGroup!.stories.isNotEmpty) {
      final stories = widget.storyGroup!.stories; // C'est une List<StoryItem>
      
      // Trouver la première story non vue en utilisant la propriété isViewed
      int startIndex = 0;
      for (int i = 0; i < stories.length; i++) {
        if (!stories[i].isViewed) {
          startIndex = i;
          break;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryPlayerPage(
            stories: stories, // Plus d'erreur ici, les types correspondent
            initialIndex: startIndex,
            username: widget.storyGroup!.username,
            userImage: widget.storyGroup!.profilePicture ?? "",
            isMine: widget.storyGroup!.isMine,
          ),
        ),
      );
    } else {
      _openProfile();
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(userId: widget.post.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double mainSize = widget.textSize;
    final double titleSize = widget.textSize + 4;
    final screenWidth = MediaQuery.of(context).size.width;
    
    double firstImageHeight = screenWidth;
    if (widget.post.imageUrls.isNotEmpty) {
      firstImageHeight = _calculateHeight(
        widget.post.imageUrls[0],
        screenWidth,
      );
    }

    String? locationText;
    try {
      locationText = (widget.post as dynamic).displayLocation;
    } catch (_) {
      locationText = widget.post.cityName ?? widget.post.placeName;
    }

    final String timeString = _formatDate(widget.post.date);

    // --- CONSTRUCTION AVATAR AVEC ANNEAU ---
    // Utilisation des propriétés du modèle
    final bool hasStory = widget.storyGroup != null && widget.storyGroup!.stories.isNotEmpty;
    final bool allSeen = widget.storyGroup?.allSeen ?? true;

    final List<Color> borderColors = allSeen 
        ? [Colors.grey[700]!, Colors.grey[600]!]
        : [dGreen, const Color(0xFF2E7D32)];

    Widget avatarWidget = CircleAvatar(
      backgroundImage: widget.post.profileImageUrl.isNotEmpty
          ? NetworkImage(widget.post.profileImageUrl)
          : null,
      backgroundColor: Colors.grey[800],
      child: widget.post.profileImageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );

    if (hasStory) {
      avatarWidget = Container(
        padding: const EdgeInsets.all(2.5), 
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: borderColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          padding: const EdgeInsets.all(2),
          child: avatarWidget,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Avatar interactif
                  GestureDetector(
                    onTap: _onAvatarTap,
                    child: avatarWidget,
                  ),
                  const SizedBox(width: 8),
                  // Pseudo interactif (toujours profil)
                  GestureDetector(
                    onTap: _openProfile,
                    child: Text(
                      widget.post.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: titleSize,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'delete' && widget.onDelete != null)
                      widget.onDelete!();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        "Modifier la légende",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: mainSize,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        "Supprimer",
                        style: TextStyle(color: Colors.red, fontSize: mainSize),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Média
        if (widget.post.imageUrls.isNotEmpty)
          SizedBox(
            height: firstImageHeight,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.post.imageUrls.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final url = widget.post.imageUrls[index];
                
                return GestureDetector(
                  onDoubleTapDown: handleDoubleTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _MediaPostItem(url: url, height: firstImageHeight),
                      
                      if (heartPosition != null && currentPage == index)
                        AnimatedBuilder(
                          animation: _heartController,
                          builder: (_, child) => Positioned(
                            left: heartPosition!.dx - 40,
                            top: heartPosition!.dy - 40,
                            child: Transform.translate(
                              offset: _moveAnimation.value * 100,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Icon(
                                  Icons.favorite,
                                  color: dGreen.withOpacity(0.8),
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

        if (widget.post.imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.post.imageUrls.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                width: currentPage == i ? 8 : 6,
                height: currentPage == i ? 8 : 6,
                decoration: BoxDecoration(
                  color: currentPage == i ? dGreen : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? dGreen : Colors.white,
                  size: titleSize + 6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                likeCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mainSize,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showCommentsModal(context),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: titleSize + 4,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                commentCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mainSize,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),

        // Légende
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDescription(),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  if (widget.post.tripName != null &&
                      widget.post.tripName!.isNotEmpty) ...[
                    _buildDot(),
                    const Icon(
                      Icons.airplanemode_active,
                      size: 14,
                      color: dGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.tripName!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (locationText != null && locationText.isNotEmpty) ...[
                    _buildDot(),
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text(
                      locationText,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  void _showCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CommentsSheet(
          postId: widget.post.id,
          commentCount: commentCount,
          onCommentAdded: () {
            setState(() {
              commentCount++;
            });
            final updatedPost = widget.post.copyWith(comments: commentCount);
            PostService.notifyPostUpdated(updatedPost);
            if (widget.onPostUpdated != null)
              widget.onPostUpdated!(updatedPost);
          },
        ),
      ),
    );
  }
}

class _MediaPostItem extends StatefulWidget {
  final String url;
  final double height;

  const _MediaPostItem({required this.url, required this.height});

  @override
  State<_MediaPostItem> createState() => _MediaPostItemState();
}

class _MediaPostItemState extends State<_MediaPostItem> {
  late VideoPlayerController _videoController;
  bool _isVideo = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final ext = p.extension(widget.url).toLowerCase();
    _isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(ext);

    if (_isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            _videoController.setLooping(true);
            _videoController.play();
          }
        }).catchError((error) {
          debugPrint("Erreur chargement vidéo: $error");
        });
    }
  }

  @override
  void dispose() {
    if (_isVideo) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideo) {
      return Image.network(
        widget.url,
        width: double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.white),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: widget.height,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: dGreen)),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }
}

// ... CLASSE _CommentsSheet (Reste inchangée, garde ton code existant pour cette partie) ...
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final int commentCount;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.commentCount,
    required this.onCommentAdded,
    Key? key,
  }) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final CommentService _commentService = CommentService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _myProfilePic;
  StreamSubscription? _commentSubscription;
  
  CommentModel? _replyingToComment;
  
  List<CommentModel> _rootComments = [];
  Map<String, List<CommentModel>> _directChildren = {}; 
  Map<String, String> _commentIdToUsername = {};
  
  Map<String, int> _visibleRepliesCount = {}; 

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _loadCurrentUser();

    _commentSubscription = CommentService.commentUpdates.listen((updatedComment) {
       _updateLocalComment(updatedComment);
    });
  }

  void _updateLocalComment(CommentModel updated) {
    final index = _comments.indexWhere((c) => c.id == updated.id);
    if (index != -1 && mounted) {
      setState(() {
        _comments[index] = updated;
        _organizeComments();
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final profile = await getMyProfile();
    if (profile != null && mounted) {
      setState(() {
        _myProfilePic = profile['profile_picture'] ?? profile['img'];
      });
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    final comments = await _commentService.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _organizeComments();
        _isLoading = false;
      });
    }
  }

  void _organizeComments() {
    _commentIdToUsername = {for (var c in _comments) c.id: c.username};
    _directChildren = {};
    _rootComments = [];

    for (var c in _comments) {
      if (c.parentCommentId == null) {
        _rootComments.add(c);
      } else {
        if (!_directChildren.containsKey(c.parentCommentId)) {
          _directChildren[c.parentCommentId!] = [];
        }
        _directChildren[c.parentCommentId!]!.add(c);
      }
    }
  }

  List<CommentModel> _getAllDescendants(String parentId) {
    List<CommentModel> descendants = [];
    if (_directChildren.containsKey(parentId)) {
      for (var child in _directChildren[parentId]!) {
        descendants.add(child);
        descendants.addAll(_getAllDescendants(child.id));
      }
    }
    return descendants;
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    String? targetParentId = _replyingToComment?.id;

    final success = await _commentService.postComment(
      widget.postId, 
      text,
      parentCommentId: targetParentId,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _textController.clear();
        _focusNode.unfocus();
        
        if (targetParentId != null) {
          String rootId = _findRootId(targetParentId);
          if ((_visibleRepliesCount[rootId] ?? 0) == 0) {
            _visibleRepliesCount[rootId] = 3;
          }
        }
        
        setState(() => _replyingToComment = null);
        widget.onCommentAdded();
        _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi du commentaire")),
        );
      }
    }
  }

  String _findRootId(String commentId) {
    String currentId = commentId;
    int safety = 0;
    while (safety < 50) {
      final comment = _comments.firstWhere((c) => c.id == currentId, orElse: () => CommentModel(id: "", postId: "", userId: "", username: "", profilePicture: "", content: "", createdAt: DateTime.now()));
      if (comment.parentCommentId == null) return comment.id;
      currentId = comment.parentCommentId!;
      safety++;
    }
    return commentId;
  }
  
  Future<void> _toggleCommentLike(CommentModel comment) async {
    final bool wasLiked = comment.isLiked;
    final updatedComment = comment.copyWith(
      isLiked: !wasLiked,
      likes: comment.likes + (wasLiked ? -1 : 1),
    );

    _updateLocalComment(updatedComment);
    CommentService.notifyCommentUpdated(updatedComment);

    bool success;
    if (wasLiked) {
      success = await _commentService.unlikeComment(comment.id);
    } else {
      success = await _commentService.likeComment(comment.id);
    }

    if (!success && mounted) {
      _updateLocalComment(comment);
      CommentService.notifyCommentUpdated(comment);
    }
  }
  
  void _replyToComment(CommentModel comment) {
    setState(() {
      _replyingToComment = comment;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _commentSubscription?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.isNegative) return "À l'instant";
    
    if (diff.inDays > 7) return "${date.day}/${date.month}";
    if (diff.inDays >= 1) return "${diff.inDays}j";
    if (diff.inHours >= 1) return "${diff.inHours}h";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m";
    return "À l'instant";
  }

  @override
  Widget build(BuildContext context) {
    const Color bgModal = Color(0xFF121212);
    const Color bgInput = Color(0xFF2C2C2C);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: bgModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${widget.commentCount} commentaires",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: dGreen))
                : _rootComments.isEmpty
                    ? Center(
                        child: Text(
                          "Sois le premier à commenter !",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _rootComments.length,
                        itemBuilder: (context, index) {
                          final rootComment = _rootComments[index];
                          return _buildCommentTree(rootComment);
                        },
                      ),
          ),
          
          if (_replyingToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Text(
                    "Réponse à ${_replyingToComment!.username}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              decoration: const BoxDecoration(
                color: bgModal,
                border: Border(top: BorderSide(color: Color(0xFF333333), width: 0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: (_myProfilePic != null && _myProfilePic!.isNotEmpty)
                        ? NetworkImage(_myProfilePic!)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: (_myProfilePic == null || _myProfilePic!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgInput,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _replyingToComment != null 
                              ? "Répondre à ${_replyingToComment!.username}..."
                              : "Ajouter un commentaire...",
                          hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isSending ? null : _sendComment,
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: dGreen, strokeWidth: 2),
                          )
                        : Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, color: dGreen, size: 24),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTree(CommentModel rootComment) {
    final allReplies = _getAllDescendants(rootComment.id);
    final int totalReplies = allReplies.length;
    final bool hasReplies = totalReplies > 0;
    
    final int showCount = _visibleRepliesCount[rootComment.id] ?? 0;
    final bool isExpanded = showCount > 0;
    final List<CommentModel> displayedReplies = allReplies.take(showCount).toList();
    final bool hasMore = showCount < totalReplies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleComment(rootComment, isReply: false, rootId: rootComment.id),
        
        if (hasReplies && !isExpanded)
          _buildRepliesToggle(
            label: "Voir les $totalReplies réponses",
            onTap: () {
              setState(() => _visibleRepliesCount[rootComment.id] = math.min(totalReplies, 3));
            },
            icon: Icons.keyboard_arrow_down,
          ),

        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...displayedReplies.map((reply) => _buildSingleComment(reply, isReply: true, rootId: rootComment.id)),
                
                Padding(
                  padding: const EdgeInsets.only(left: 56, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20, 
                        height: 1, 
                        color: Colors.grey[700],
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      
                      if (hasMore) ...[
                        GestureDetector(
                          onTap: () {
                            setState(() => _visibleRepliesCount[rootComment.id] = math.min(totalReplies, showCount + 3));
                          },
                          child: Text(
                            "Afficher ${math.min(3, totalReplies - showCount)} de plus",
                            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      GestureDetector(
                        onTap: () {
                          setState(() => _visibleRepliesCount[rootComment.id] = 0);
                        },
                        child: const Text(
                          "Masquer",
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRepliesToggle({required String label, required VoidCallback onTap, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 20, 
              height: 1, 
              color: Colors.grey[700],
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.grey[500], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleComment(CommentModel comment, {required bool isReply, required String rootId}) {
    final double leftPadding = isReply ? 48.0 : 0.0;
    final double avatarSize = isReply ? 12.0 : 16.0;
    const Color textGrey = Color(0xFF8A8A8A);
    const Color userGrey = Color(0xFFB0B0B0);

    String? parentUsername;
    if (isReply && comment.parentCommentId != null) {
      parentUsername = _commentIdToUsername[comment.parentCommentId];
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: leftPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: avatarSize,
            backgroundImage: comment.profilePicture.isNotEmpty
                ? NetworkImage(comment.profilePicture)
                : null,
            backgroundColor: Colors.grey[800],
            child: comment.profilePicture.isEmpty
                ? Icon(Icons.person, size: avatarSize + 4, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        color: userGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (parentUsername != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.play_arrow, size: 10, color: Colors.grey),
                      ),
                      Text(
                        parentUsername,
                        style: const TextStyle(
                          color: userGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(color: textGrey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: const Text(
                        "Répondre",
                        style: TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleCommentLike(comment),
                child: Icon(
                  comment.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: comment.isLiked ? dGreen : Colors.grey[600],
                ),
              ),
              if (comment.likes > 0)
                Text(
                  "${comment.likes}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}