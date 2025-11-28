import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart'; // Assurez-vous d'importer vos constantes pour dGreen

class PostGridItem extends StatelessWidget {
  final String imageUrl;
  final bool isMultiple; // Nouveau paramètre
  final VoidCallback onTap;

  const PostGridItem({
    super.key,
    required this.imageUrl,
    this.isMultiple = false, // Par défaut à false
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // L'image de fond
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[800]),
          ),
          
          // L'icône si plusieurs images (style identique au GalleryPicker)
          if (isMultiple)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: dGreen, // Couleur importée de constants.dart
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}