import 'package:flutter/material.dart';

class PostGridItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const PostGridItem({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[800]),
      ),
    );
  }
}