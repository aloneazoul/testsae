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

  // --- FONCTION DE CORRECTION DE DATE (IDENTIQUE AU MODEL) ---
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();

    // 1. Correction du format
    String isoString = dateStr.replaceFirst(' ', 'T');

    // 2. Ajout du Z pour UTC
    if (!isoString.endsWith('Z') && !isoString.contains('+')) {
      isoString += 'Z';
    }

    // 3. Conversion UTC -> Local
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

                // Création du modèle avec la date corrigée
                PostModel postModel = PostModel(
                  id: postId.toString(),
                  userId: postUserId,
                  userName: widget.userData['username'] ?? widget.userData['pseudo'] ?? "Inconnu",
                  imageUrls: imageUrls,
                  caption: postData['post_description'] ?? "",
                  likes: postData['likes_count'] ?? postData['nb_likes'] ?? 0,
                  comments: postData['comments_count'] ?? postData['nb_comments'] ?? 0,
                  isLiked: (postData['is_liked'] != null && postData['is_liked'] > 0),
                  
                  // --- UTILISATION DE LA FONCTION DE DATE ICI ---
                  date: _parseDate(postData['created_at']?.toString() ?? postData['publication_date']?.toString()),
                  
                  profileImageUrl: widget.userData['img'] ?? widget.userData['profile_picture'] ?? "",
                  
                  // Mapping des nouvelles infos (Voyage / Ville)
                  tripName: postData['trip_title'],
                  placeName: postData['place_name'],
                  cityName: postData['city_name'],
                  latitude: postData['latitude'] != null ? double.tryParse(postData['latitude'].toString()) : null,
                );

                return PostCard(
                  post: postModel,
                  isOwner: isOwner,
                  onLikeChanged: (bool liked, int count) {
                    hasDataChanged = true;
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