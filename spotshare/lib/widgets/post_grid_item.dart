import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) =>
                Container(color: Colors.grey[800]),
          ),

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
