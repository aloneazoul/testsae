import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/utils/constants.dart';

class PostFeedPage extends StatefulWidget {
  final List<dynamic> postsRaw;
  final Map<String, dynamic> userData;
  final int initialIndex;
  final String currentLoggedUserId;

  const PostFeedPage({
    Key? key,
    required this.postsRaw,
    required this.userData,
    required this.initialIndex,
    required this.currentLoggedUserId,
  }) : super(key: key);

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  late final ScrollController _scrollController;
  final PostService _postService = PostService();

  // Cette variable sert à savoir si on doit demander un refresh au retour
  bool hasDataChanged = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && widget.initialIndex > 0) {
        _scrollController.jumpTo(widget.initialIndex * 500.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  // Fonction pour quitter la page en renvoyant "true" si modif
  void _goBack() {
    Navigator.pop(context, hasDataChanged);
  }

  @override
  Widget build(BuildContext context) {
    String pseudo = widget.userData['pseudo'] ?? 'Publications';

    return WillPopScope(
      // Intercepte le bouton retour physique Android / Swipe iOS
      onWillPop: () async {
        _goBack();
        return false; // On gère le pop manuellement
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack, // Utilise notre fonction de retour
          ),
          title: Text(pseudo, style: const TextStyle(color: Colors.white)),
        ),
        body: ListView.builder(
          controller: _scrollController,
          itemCount: widget.postsRaw.length,
          itemBuilder: (context, index) {
            final postData = widget.postsRaw[index];
            final postId = postData['post_id'];
            final String postUserId = (postData['user_id'] ?? "").toString();
            final bool isOwner = (postUserId == widget.currentLoggedUserId);

            return FutureBuilder<List<dynamic>>(
              future: _postService.getMediaTripPosts(postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(color: dGreen),
                    ),
                  );
                }

                final List<String> imageUrls = (snapshot.data as List)
                    .map((e) => e['media_url'] as String)
                    .toList();

                if (imageUrls.isEmpty) return const SizedBox.shrink();

                // Création du modèle
                PostModel postModel = PostModel(
                  id: postId.toString(),
                  userId: postUserId,
                  userName: widget.userData['pseudo'] ?? "Inconnu",
                  imageUrls: imageUrls,
                  caption: postData['post_description'] ?? "",
                  likes: postData['likes_count'] ?? postData['nb_likes'] ?? 0,
                  comments:
                      postData['comments_count'] ??
                      postData['nb_comments'] ??
                      0,
                  // C'est cette info qui sera corrigée grâce au Backend
                  isLiked:
                      (postData['is_liked'] != null &&
                      postData['is_liked'] > 0),
                  date:
                      DateTime.tryParse(postData['created_at'] ?? "") ??
                      DateTime.now(),
                  profileImageUrl: widget.userData['img'] ?? "",
                );

                return PostCard(
                  post: postModel,
                  isOwner: isOwner,

                  // Callback quand on like
                  onLikeChanged: (bool liked, int count) {
                    // On note que quelque chose a changé
                    hasDataChanged = true;
                  },

                  onDelete: () async {
                    final bool deleted = await _handleDeletePost(postModel.id);
                    if (deleted) {
                      // Si suppression, on force le refresh direct
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
