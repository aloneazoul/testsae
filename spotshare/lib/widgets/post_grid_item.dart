import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:path/path.dart' as p;

class PostGridItem extends StatelessWidget {
  final String imageUrl;
  final bool isMultiple;
  final VoidCallback onTap;

  const PostGridItem({
    super.key,
    required this.imageUrl,
    this.isMultiple = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Détection si l'URL est une vidéo
    final ext = p.extension(imageUrl).toLowerCase();
    final isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(ext);

    // 2. Si c'est une vidéo, on demande à Cloudinary l'image (.jpg) au lieu du fichier vidéo
    String displayUrl = imageUrl;
    if (isVideo) {
      // Remplace l'extension vidéo par .jpg pour avoir la miniature
      displayUrl = imageUrl.replaceAll(RegExp(r'\.(mp4|mov|avi|mkv)$', caseSensitive: false), '.jpg');
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Affiche l'image (ou la miniature de la vidéo)
          Image.network(
            displayUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) =>
                Container(color: Colors.grey[800]),
          ),

          // 3. Ajoute une icône PLAY si c'est une vidéo
          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white70,
                size: 40,
              ),
            ),

          // Icône pour indiquer plusieurs médias
          if (isMultiple)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: dGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.copy, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}