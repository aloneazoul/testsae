import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/utils/constants.dart';

class PostFeedPage extends StatefulWidget {
  final List<dynamic> postsRaw;
  final Map<String, dynamic> userData;
  final String initialPostId;
  final String currentLoggedUserId;

  const PostFeedPage({
    Key? key,
    required this.postsRaw,
    required this.userData,
    required this.initialPostId,
    required this.currentLoggedUserId,
  }) : super(key: key);

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  late final ScrollController _scrollController;
  final PostService _postService = PostService();
  final Map<dynamic, GlobalKey> _postKeys = {};
  final Map<dynamic, Future<List<dynamic>>> _mediaFutures = {};
  late int _initialIndex;

  late List<dynamic> _posts;
  StreamSubscription? _postSubscription;
  bool hasDataChanged = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _posts = List.from(widget.postsRaw);

    _postSubscription = PostService.postUpdates.listen((updatedPost) {
      _handleGlobalUpdate(updatedPost);
    });

    for (var post in _posts) {
      _postKeys[post['post_id']] = GlobalKey();
    }

    _initialIndex = _posts.indexWhere(
      (p) => p['post_id'].toString() == widget.initialPostId,
    );
    if (_initialIndex == -1) _initialIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialPost();
    });
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialPost() {
    const double postHeight = 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;

      if (_initialIndex >= _posts.length - 1) {
        _scrollController.jumpTo(maxScroll);
        return;
      }

      final targetOffset = _initialIndex * postHeight;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleGlobalUpdate(PostModel updatedPost) {
    final index = _posts.indexWhere(
      (p) => p['post_id'].toString() == updatedPost.id,
    );

    if (index != -1 && mounted) {
      setState(() {
        _posts[index]['likes_count'] = updatedPost.likes;
        _posts[index]['comments_count'] = updatedPost.comments;
        _posts[index]['is_liked'] = updatedPost.isLiked ? 1 : 0;
        hasDataChanged = true;
      });
    }
  }

  Future<bool> _handleDeletePost(String postId) async {
    int? id = int.tryParse(postId);
    if (id != null) {
      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Supprimer le post ?"),
          content: const Text("Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                final bool success = await _postService.deletePost(id);
                Navigator.pop(ctx, success);
              },
              child: const Text(
                "Supprimer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return false;
  }

  void _goBack() {
    Navigator.pop(context, hasDataChanged);
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    String isoString = dateStr.replaceFirst(' ', 'T');
    if (!isoString.endsWith('Z') && !isoString.contains('+')) isoString += 'Z';
    return DateTime.tryParse(isoString)?.toLocal() ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    String pseudo = widget.userData['pseudo'] ?? 'Publications';

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: Text(pseudo, style: const TextStyle(color: Colors.white)),
        ),
        body: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 150),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final postData = _posts[index];
            final postId = postData['post_id'];
            final String postUserId = (postData['user_id'] ?? "").toString();
            final bool isOwner = (postUserId == widget.currentLoggedUserId);
            final future = _mediaFutures.putIfAbsent(
              postId,
              () => _postService.getMediaTripPosts(postId),
            );
            const double _estimatedPostHeight = 600;

            return FutureBuilder<List<dynamic>>(
              key: ValueKey(postId),
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: _estimatedPostHeight,
                    child: Center(
                      child: CircularProgressIndicator(color: dGreen),
                    ),
                  );
                }

                final List<String> imageUrls = (snapshot.data as List)
                    .map((e) => e['media_url'] as String)
                    .toList();
                if (imageUrls.isEmpty) return const SizedBox.shrink();

                PostModel postModel = PostModel(
                  id: postId.toString(),
                  userId: postUserId,
                  userName:
                      widget.userData['username'] ??
                      widget.userData['pseudo'] ??
                      "Inconnu",
                  imageUrls: imageUrls,
                  caption: postData['post_description'] ?? "",
                  likes: postData['likes_count'] ?? postData['nb_likes'] ?? 0,
                  comments:
                      postData['comments_count'] ??
                      postData['nb_comments'] ??
                      0,
                  isLiked:
                      (postData['is_liked'] != null &&
                      postData['is_liked'] > 0),
                  date: _parseDate(
                    postData['created_at']?.toString() ??
                        postData['publication_date']?.toString(),
                  ),
                  profileImageUrl:
                      widget.userData['img'] ??
                      widget.userData['profile_picture'] ??
                      "",
                  tripName: postData['trip_title'],
                  placeName: postData['place_name'],
                  cityName: postData['city_name'],
                  latitude: postData['latitude'] != null
                      ? double.tryParse(postData['latitude'].toString())
                      : null,
                );

                return PostCard(
                  key: _postKeys[postId],
                  post: postModel,
                  isOwner: isOwner,
                  onPostUpdated: (updated) {
                    hasDataChanged = true;
                    _handleGlobalUpdate(updated);
                  },
                  onDelete: () async {
                    final bool deleted = await _handleDeletePost(postModel.id);
                    if (deleted) {
                      Navigator.pop(context, true);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
