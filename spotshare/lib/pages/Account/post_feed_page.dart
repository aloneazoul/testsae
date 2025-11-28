import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
// Attention à l'import : le PostCard est dans widgets maintenant
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/utils/constants.dart';

class PostFeedPage extends StatefulWidget {
  final List<dynamic> postsRaw; // La liste JSON brute des posts
  final Map<String, dynamic>
  userData; // Les infos (pseudo, avatar) du PROFIL visité
  final int initialIndex; // L'index du post cliqué (pour le scroll)
  final String currentLoggedUserId; // L'ID de celui qui tient le téléphone

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Scroll automatique vers le post cliqué après le rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && widget.initialIndex > 0) {
        // On estime la hauteur d'un post à 500px pour scroller approximativement
        _scrollController.jumpTo(widget.initialIndex * 500.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fonction de suppression (squelette)
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
                // 🔥 Appel API de suppression

                final bool success = await _postService.deletePost(id);

                // Si la suppression a réussi → renvoyer true
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

  @override
  Widget build(BuildContext context) {
    // Le pseudo affiché en haut est celui du profil visité
    String pseudo = widget.userData['pseudo'] ?? 'Publications';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(pseudo, style: const TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.postsRaw.length,
        itemBuilder: (context, index) {
          final postData = widget.postsRaw[index];
          final postId = postData['post_id'];

          // L'ID de l'auteur de ce post spécifique
          final String postUserId = (postData['user_id'] ?? "").toString();

          // Comparaison : Est-ce que l'utilisateur connecté est l'auteur ?
          // C'est ce booléen qui active ou désactive le menu "Supprimer"
          final bool isOwner = (postUserId == widget.currentLoggedUserId);

          // On charge les images du post
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

              // Création du modèle pour l'affichage
              PostModel postModel = PostModel(
                id: postId.toString(),
                userId: postUserId,
                userName: widget.userData['pseudo'] ?? "Inconnu",
                imageUrls: imageUrls,
                caption: postData['post_description'] ?? "",
                likes: postData['nb_likes'] ?? 0,
                comments: postData['nb_comments'] ?? 0,
                date:
                    DateTime.tryParse(postData['created_at'] ?? "") ??
                    DateTime.now(),
                profileImageUrl: widget.userData['img'] ?? "",
              );

              return PostCard(
                post: postModel,
                isOwner: isOwner, // <--- C'est ici que tout se joue
                onDelete: () async {
                  final bool deleted = await _handleDeletePost(postModel.id);

                  if (deleted) {
                    Navigator.pop(
                      context,
                      true,
                    ); // 🔥 On renvoie true à la page profil
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
