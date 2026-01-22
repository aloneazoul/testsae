import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/models/comment_model.dart';
import 'package:spotshare/pages/Account/profile_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/comment_service.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/utils/constants.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isOwner;
  final VoidCallback? onDelete;
  final Function(PostModel updatedPost)? onPostUpdated;
  final double textSize;

  const PostCard({
    required this.post,
    this.isOwner = false,
    this.onDelete,
    this.textSize = 12,
    this.onPostUpdated,
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
      250,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: widget.post.userId),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.post.profileImageUrl.isNotEmpty
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: titleSize,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
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
                      Image.network(
                        url,
                        width: double.infinity,
                        height: firstImageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _myProfilePic;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _loadCurrentUser();
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
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final success = await _commentService.postComment(widget.postId, text);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _textController.clear();
        FocusScope.of(context).unfocus();
        widget.onCommentAdded();
        _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi du commentaire"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return "${date.day}-${date.month}";
    if (diff.inDays >= 1) return "${diff.inDays}j";
    if (diff.inHours >= 1) return "${diff.inHours}h";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m";
    return "À l'instant";
  }

  @override
  Widget build(BuildContext context) {
    const Color bgModal = Color(0xFF121212);
    const Color bgInput = Color(0xFF2C2C2C);
    const Color textGrey = Color(0xFF8A8A8A);
    const Color userGrey = Color(0xFFB0B0B0);

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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: dGreen))
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      "Sois le premier à commenter !",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: comment.profilePicture.isNotEmpty
                                  ? NetworkImage(comment.profilePicture)
                                  : null,
                              backgroundColor: Colors.grey[800],
                              child: comment.profilePicture.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.username,
                                    style: const TextStyle(
                                      color: userGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatDate(comment.createdAt),
                                        style: const TextStyle(
                                          color: textGrey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        "Répondre",
                                        style: TextStyle(
                                          color: textGrey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                color: bgModal,
                border: Border(
                  top: BorderSide(color: Color(0xFF333333), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        (_myProfilePic != null && _myProfilePic!.isNotEmpty)
                        ? NetworkImage(_myProfilePic!)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: (_myProfilePic == null || _myProfilePic!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Ajouter un commentaire...",
                          hintStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
                            child: CircularProgressIndicator(
                              color: dGreen,
                              strokeWidth: 2,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward,
                              color: dGreen,
                              size: 24,
                            ),
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
}
