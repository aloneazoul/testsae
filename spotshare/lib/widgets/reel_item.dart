import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Account/profile_page.dart';
// Import pour la détection d'extension
import 'package:path/path.dart' as p; 

class ReelItem extends StatefulWidget {
  final PostModel post;
  final bool isVisible; // Pour lancer/mettre en pause la vidéo

  const ReelItem({
    Key? key,
    required this.post,
    this.isVisible = false,
  }) : super(key: key);

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  VideoPlayerController? _videoController;
  bool _isLiked = false;
  int _likesCount = 0;
  final PostService _postService = PostService();
  
  // NOUVEAU : Pour savoir si c'est une vidéo AVANT le chargement
  bool _isVideo = false; 

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likes;
    _initializeMedia();
  }

  void _initializeMedia() {
    if (widget.post.imageUrls.isNotEmpty) {
      String url = widget.post.imageUrls.first;
      
      // 1. Détection Robuste (comme dans PostCard)
      final uri = Uri.tryParse(url);
      final path = uri != null ? uri.path : url;
      final ext = p.extension(path).toLowerCase();
      
      bool detected = ['.mp4', '.mov', '.avi', '.mkv'].contains(ext);
      if (!detected) {
        detected = url.contains('/video/');
      }

      setState(() {
        _isVideo = detected;
      });

      // 2. Si c'est une vidéo, on initialise le player
      if (_isVideo) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {}); // Rafraîchir pour afficher la vidéo
              if (widget.isVisible) {
                _videoController!.play();
                _videoController!.setLooping(true);
              }
            }
          }).catchError((err) {
             print("Erreur vidéo Reel: $err");
          });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible && _videoController != null && _videoController!.value.isInitialized) {
      if (widget.isVisible) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      await _postService.likePost(widget.post.id);
    } else {
      await _postService.unlikePost(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. LE FOND (Média)
        Container(
          color: Colors.black, // Fond noir par défaut
          child: _buildMediaContent(),
        ),

        // 2. OMBRE DÉGRADÉE
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        // 3. INFOS (Bas Gauche)
        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: widget.post.userId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: widget.post.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.post.profileImageUrl)
                          : null,
                      child: widget.post.profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.post.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (widget.post.caption.isNotEmpty)
                Text(
                  widget.post.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              if (widget.post.tripName != null || widget.post.displayLocation != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.post.displayLocation ?? widget.post.tripName ?? "",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // 4. ACTIONS (Bas Droite)
        Positioned(
          bottom: 40,
          right: 10,
          child: Column(
            children: [
              _buildActionBtn(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                label: "$_likesCount",
                onTap: _toggleLike,
              ),
              _buildActionBtn(
                icon: Icons.comment,
                label: "${widget.post.comments}",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Commentaires (à venir)")),
                  );
                },
              ),
              _buildActionBtn(
                icon: Icons.share,
                label: "Partager",
                onTap: () {},
              ),
              _buildActionBtn(
                icon: Icons.more_vert,
                label: "",
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContent() {
    // CAS 1 : C'est une vidéo, mais elle charge encore
    if (_isVideo && (_videoController == null || !_videoController!.value.isInitialized)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // CAS 2 : Vidéo chargée et prête
    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    } 
    
    // CAS 3 : C'est une Image (Post classique affiché en mode Reel ou Fallback)
    else if (widget.post.imageUrls.isNotEmpty) {
      return Image.network(
        widget.post.imageUrls.first,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, loading) {
          if (loading == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.error_outline, color: Colors.white54),
        ),
      );
    } else {
      return Container(color: Colors.black);
    }
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
            Icon(icon, color: color, size: 32),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}