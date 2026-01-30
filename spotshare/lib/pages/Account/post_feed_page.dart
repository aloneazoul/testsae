import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/reel_item.dart';
import 'package:spotshare/utils/constants.dart';

class PostFeedPage extends StatefulWidget {
  final List<dynamic> postsRaw;
  final Map<String, dynamic> userData;
  final String initialPostId;
  final String currentLoggedUserId;
  final bool? isMemoryFeed; // NOUVEAU PARAMÈTRE POUR FORCER LE MODE

  const PostFeedPage({
    Key? key,
    required this.postsRaw,
    required this.userData,
    required this.initialPostId,
    required this.currentLoggedUserId,
    this.isMemoryFeed, // AJOUT
  }) : super(key: key);

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  late final ScrollController _listScrollController;
  late final PageController _pageController;
  
  final PostService _postService = PostService();
  final Map<dynamic, GlobalKey> _postKeys = {};
  final Map<dynamic, Future<List<dynamic>>> _mediaFutures = {};
  
  late int _currentIndex;
  late List<dynamic> _posts;
  StreamSubscription? _postSubscription;
  
  bool _isMemoryFeed = false;
  bool _needsHardRefresh = false;

  @override
  void initState() {
    super.initState();
    _posts = List.from(widget.postsRaw);

    // DÉTECTION DU MODE : On priorise le paramètre explicite, sinon on devine via les données
    if (widget.isMemoryFeed != null) {
      _isMemoryFeed = widget.isMemoryFeed!;
    } else if (_posts.isNotEmpty && _posts.first['post_type'] == 'MEMORY') {
      _isMemoryFeed = true;
    }

    _postSubscription = PostService.postUpdates.listen((updatedPost) {
      _handleGlobalUpdate(updatedPost);
    });

    for (var post in _posts) {
      _postKeys[post['post_id']] = GlobalKey();
    }

    int initialIndex = _posts.indexWhere(
      (p) => p['post_id'].toString() == widget.initialPostId,
    );
    if (initialIndex == -1) initialIndex = 0;
    _currentIndex = initialIndex;

    if (_isMemoryFeed) {
      _pageController = PageController(initialPage: initialIndex);
    } else {
      _listScrollController = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToListIndex(initialIndex);
      });
    }
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    if (_isMemoryFeed) {
      _pageController.dispose();
    } else {
      _listScrollController.dispose();
    }
    super.dispose();
  }

  void _scrollToListIndex(int index) {
    const double estimatedHeight = 600;
    if (!_listScrollController.hasClients) return;
    
    final maxScroll = _listScrollController.position.maxScrollExtent;
    final targetOffset = index * estimatedHeight;

    if (targetOffset >= maxScroll) {
      _listScrollController.jumpTo(maxScroll);
    } else {
      _listScrollController.jumpTo(targetOffset);
    }
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
          title: const Text("Supprimer ?"),
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
      
      if (result == true) {
        setState(() {
          _needsHardRefresh = true; 
          _posts.removeWhere((p) => p['post_id'].toString() == postId);
        });
        return true;
      }
    }
    return false;
  }

  void _goBack() {
    Navigator.pop(context, _needsHardRefresh);
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    String isoString = dateStr.replaceFirst(' ', 'T');
    if (!isoString.endsWith('Z') && !isoString.contains('+')) isoString += 'Z';
    return DateTime.tryParse(isoString)?.toLocal() ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // === MODE MEMORIES (TIKTOK) ===
    if (_isMemoryFeed) {
      return WillPopScope(
        onWillPop: () async {
          _goBack();
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.black, 
          // extendBodyBehindAppBar est false pour respecter la Safe Area par défaut
          // Mais ici on veut le fond noir total, donc on utilise un Container root + SafeArea
          body: Container(
            color: Colors.black,
            child: SafeArea(
              top: true,
              bottom: false, 
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _posts.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildItem(index);
                    },
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: _goBack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // === MODE POST CLASSIQUE ===
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
          controller: _listScrollController,
          padding: const EdgeInsets.only(bottom: 150),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return _buildItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final postData = _posts[index];
    final postId = postData['post_id'];
    final String postUserId = (postData['user_id'] ?? "").toString();
    final bool isOwner = (postUserId == widget.currentLoggedUserId);
    
    final future = _mediaFutures.putIfAbsent(
      postId,
      () => _postService.getMediaTripPosts(postId),
    );

    return FutureBuilder<List<dynamic>>(
      key: ValueKey(postId),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: dGreen),
            ),
          );
        }

        final List<String> imageUrls = (snapshot.data as List? ?? [])
            .map((e) => e['media_url'] as String)
            .toList();
            
        if (imageUrls.isEmpty) return const SizedBox.shrink();

        PostModel postModel = PostModel(
          id: postId.toString(),
          userId: postUserId,
          userName: widget.userData['username'] ?? widget.userData['pseudo'] ?? "Inconnu",
          imageUrls: imageUrls,
          caption: postData['post_description'] ?? "",
          likes: postData['likes_count'] ?? postData['nb_likes'] ?? 0,
          comments: postData['comments_count'] ?? postData['nb_comments'] ?? 0,
          isLiked: (postData['is_liked'] != null && (postData['is_liked'] == 1 || postData['is_liked'] == true)),
          date: _parseDate(postData['created_at']?.toString() ?? postData['publication_date']?.toString()),
          profileImageUrl: widget.userData['img'] ?? widget.userData['profile_picture'] ?? "",
          tripName: postData['trip_title'],
          placeName: postData['place_name'],
          cityName: postData['city_name'],
          latitude: postData['latitude'] != null
              ? double.tryParse(postData['latitude'].toString())
              : null,
        );

        if (_isMemoryFeed) {
          return ReelItem(
            key: _postKeys[postId],
            post: postModel,
            isVisible: index == _currentIndex,
          );
        } else {
          return PostCard(
            key: _postKeys[postId],
            post: postModel,
            isOwner: isOwner,
            onPostUpdated: (updated) {
              _handleGlobalUpdate(updated);
            },
            onDelete: () async {
              final bool deleted = await _handleDeletePost(postModel.id);
              if (deleted) {
                // logique de suppression
              }
            },
          );
        }
      },
    );
  }
}