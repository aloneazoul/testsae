import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Account/profile_page.dart';
import 'package:path/path.dart' as p;
import 'package:spotshare/services/comment_service.dart';
import 'package:spotshare/models/comment_model.dart';
import 'package:spotshare/services/user_service.dart';

class ReelItem extends StatefulWidget {
  final PostModel post;
  final bool isVisible;

  const ReelItem({Key? key, required this.post, this.isVisible = false})
    : super(key: key);

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  final PostService _postService = PostService();
  bool _isVideo = false;
  bool _hasError = false;

  bool _isFollowing = false;
  bool _isMe = false;
  bool _isDescriptionExpanded = false;

  Offset? _heartPosition;
  late final AnimationController _heartController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _syncStateFromWidget();
    _initializeMedia();
    _checkFollowStatus();

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
  }

  void _syncStateFromWidget() {
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likes;
    _commentsCount = widget.post.comments;
  }

  Future<void> _checkFollowStatus() async {
    final myProfile = await getMyProfile();
    if (myProfile == null) return;

    final String myId = myProfile['user_id'].toString();
    if (myId == widget.post.userId) {
      if (mounted) setState(() => _isMe = true);
      return;
    }

    final authorProfile = await getUserById(widget.post.userId);
    if (authorProfile != null && mounted) {
      setState(() {
        _isFollowing = authorProfile['is_following'] == true;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    bool success;
    if (_isFollowing) {
      success = await followUser(widget.post.userId);
    } else {
      success = await unfollowUser(widget.post.userId);
    }

    if (!success && mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.post.imageUrls.isEmpty) return;

    String url = widget.post.imageUrls.first;

    bool detected = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
    ].any((e) => url.toLowerCase().endsWith(e));
    if (!detected) detected = url.contains('/video/');

    if (mounted) setState(() => _isVideo = detected);

    if (_isVideo) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
        await _videoController!.initialize();

        if (mounted) {
          setState(() => _hasError = false);
          if (widget.isVisible) {
            _videoController!.setLooping(true);
            _videoController!.play();
          }
        }
      } catch (e) {
        print("Erreur vidéo Reel: $e");
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      setState(() => _syncStateFromWidget());
      // Arrêter et réinitialiser la vidéo si c'est un nouveau post
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.pause();
        _videoController!.dispose();
        _videoController = null;
      }
      _initializeMedia();
      return;
    }

    // Gérer la visibilité du widget
    if (widget.isVisible != oldWidget.isVisible) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        if (widget.isVisible) {
          _videoController!.play();
        } else {
          _videoController!.pause();
          // Réinitialiser à la position 0 quand pas visible
          _videoController!.seekTo(Duration.zero);
        }
      }
    }
  }

  @override
  void dispose() {
    // Arrêter et disposer la vidéo complètement
    if (_videoController != null) {
      if (_videoController!.value.isInitialized) {
        _videoController!.pause();
        _videoController!.seekTo(Duration.zero);
      }
      _videoController!.dispose();
    }
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    PostService.notifyPostUpdated(
      widget.post.copyWith(
        isLiked: _isLiked,
        likes: _likesCount,
        comments: _commentsCount,
      ),
    );

    bool success;
    if (_isLiked) {
      success = await _postService.likePost(widget.post.id);
    } else {
      success = await _postService.unlikePost(widget.post.id);
    }

    if (!success && mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      PostService.notifyPostUpdated(
        widget.post.copyWith(
          isLiked: _isLiked,
          likes: _likesCount,
          comments: _commentsCount,
        ),
      );
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _heartPosition = details.localPosition;
    });
    _heartController.forward(from: 0);

    if (!_isLiked) {
      _toggleLike();
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CommentsSheet(
          postId: widget.post.id,
          commentCount: _commentsCount,
          onCommentAdded: () {
            setState(() => _commentsCount++);
            PostService.notifyPostUpdated(
              widget.post.copyWith(
                isLiked: _isLiked,
                likes: _likesCount,
                comments: _commentsCount,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTapDown: _handleDoubleTap,
          onTap: () {
            if (_videoController != null &&
                _videoController!.value.isInitialized) {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            }
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                _buildMediaContent(),
                if (_isVideo &&
                    _videoController != null &&
                    _videoController!.value.isInitialized &&
                    !_videoController!.value.isPlaying)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Icon(
                        Icons.play_arrow,
                        size: 50,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_heartPosition != null)
          AnimatedBuilder(
            animation: _heartController,
            builder: (_, child) => Positioned(
              left: _heartPosition!.dx - 50,
              top: _heartPosition!.dy - 50,
              child: Transform.translate(
                offset: _moveAnimation.value * 100,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: const Icon(Icons.favorite, color: dGreen, size: 100),
                ),
              ),
            ),
          ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userId: widget.post.userId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.post.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.post.profileImageUrl)
                          : null,
                      backgroundColor: Colors.grey[800],
                      child: widget.post.profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.post.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(width: 12),

                    if (!_isMe)
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isFollowing ? Colors.transparent : dGreen,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isFollowing ? Colors.white70 : dGreen,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _isFollowing ? "Suivi" : "Suivre",
                            style: TextStyle(
                              color: _isFollowing ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (widget.post.caption.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDescriptionExpanded
                              ? widget.post.caption
                              : (widget.post.caption.length > 60
                                    ? "${widget.post.caption.substring(0, 60)}..."
                                    : widget.post.caption),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2),
                            ],
                          ),
                        ),
                        if (widget.post.caption.length > 60)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _isDescriptionExpanded
                                  ? "Voir moins"
                                  : "Voir plus",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              if (widget.post.tripName != null ||
                  widget.post.displayLocation != null)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.post.displayLocation ??
                            widget.post.tripName ??
                            "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        Positioned(
          bottom: 40,
          right: 10,
          child: Column(
            children: [
              _buildActionBtn(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? dGreen : Colors.white,
                label: "$_likesCount",
                onTap: _toggleLike,
              ),
              _buildActionBtn(
                icon: Icons.comment,
                label: "$_commentsCount",
                onTap: () => _showComments(context),
              ),
              _buildActionBtn(
                icon: Icons.share,
                label: "Partager",
                onTap: () {},
              ),
              _buildActionBtn(icon: Icons.more_vert, label: "", onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // Suppression du Container avec decoration
            Icon(
              icon,
              color: color,
              size: 36,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 40),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() => _hasError = false);
                _initializeMedia();
              },
              child: const Text("Réessayer", style: TextStyle(color: dGreen)),
            ),
          ],
        ),
      );
    }

    if (_isVideo &&
        (_videoController == null || !_videoController!.value.isInitialized)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (widget.post.imageUrls.isNotEmpty) {
      return Image.network(
        widget.post.imageUrls.first,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, loading) {
          if (loading == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.error_outline, color: Colors.white54),
        ),
      );
    } else {
      return Container(color: Colors.black);
    }
  }
}

// === GESTION DES COMMENTAIRES (PAGINATION 3 + FLATTEN) ===
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

    _commentSubscription = CommentService.commentUpdates.listen((
      updatedComment,
    ) {
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
          const SnackBar(
            content: Text("Erreur lors de l'envoi du commentaire"),
          ),
        );
      }
    }
  }

  String _findRootId(String commentId) {
    String currentId = commentId;
    int safety = 0;
    while (safety < 50) {
      final comment = _comments.firstWhere(
        (c) => c.id == currentId,
        orElse: () => CommentModel(
          id: "",
          postId: "",
          userId: "",
          username: "",
          profilePicture: "",
          content: "",
          createdAt: DateTime.now(),
        ),
      );
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
                : _rootComments.isEmpty
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
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
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
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToComment != null
                              ? "Répondre à ${_replyingToComment!.username}..."
                              : "Ajouter un commentaire...",
                          hintStyle: const TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
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

  Widget _buildCommentTree(CommentModel rootComment) {
    final allReplies = _getAllDescendants(rootComment.id);
    final int totalReplies = allReplies.length;
    final bool hasReplies = totalReplies > 0;

    final int showCount = _visibleRepliesCount[rootComment.id] ?? 0;
    final bool isExpanded = showCount > 0;
    final List<CommentModel> displayedReplies = allReplies
        .take(showCount)
        .toList();
    final bool hasMore = showCount < totalReplies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleComment(
          rootComment,
          isReply: false,
          rootId: rootComment.id,
        ),

        if (hasReplies && !isExpanded)
          _buildRepliesToggle(
            label: "Voir les $totalReplies réponses",
            onTap: () {
              setState(
                () =>
                    _visibleRepliesCount[rootComment.id] = min(totalReplies, 3),
              );
            },
            icon: Icons.keyboard_arrow_down,
          ),

        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...displayedReplies.map(
                  (reply) => _buildSingleComment(
                    reply,
                    isReply: true,
                    rootId: rootComment.id,
                  ),
                ),

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
                            setState(
                              () => _visibleRepliesCount[rootComment.id] = min(
                                totalReplies,
                                showCount + 3,
                              ),
                            );
                          },
                          child: Text(
                            "Afficher ${min(3, totalReplies - showCount)} de plus",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],

                      GestureDetector(
                        onTap: () {
                          setState(
                            () => _visibleRepliesCount[rootComment.id] = 0,
                          );
                        },
                        child: const Text(
                          "Masquer",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildRepliesToggle({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
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
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.grey[500], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleComment(
    CommentModel comment, {
    required bool isReply,
    required String rootId,
  }) {
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
                        child: Icon(
                          Icons.play_arrow,
                          size: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        parentUsername,
                        style: const TextStyle(
                          color: userGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
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
                      style: const TextStyle(color: textGrey, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: const Text(
                        "Répondre",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
