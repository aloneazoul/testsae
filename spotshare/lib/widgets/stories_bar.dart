import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';

class StoriesBar extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final VoidCallback? onAddStoryTap;

  const StoriesBar({Key? key, required this.stories, this.onAddStoryTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final bool isMine = story['is_mine'] == true;
          final String imageUrl = story['image'] ?? "";
          final String name = story['name'] ?? "";

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 12 : 8, right: 8),
            child: Column(
              children: [
                _buildAvatarCircle(context, imageUrl, isMine),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarCircle(
    BuildContext context,
    String imageUrl,
    bool isMine,
  ) {
    if (isMine) {
      return Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2, right: 2),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[800],
              backgroundImage: (imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onAddStoryTap,
              child: Container(
                decoration: BoxDecoration(
                  color: dGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.add, color: Colors.black, size: 14),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [dGreen, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[800],
          backgroundImage: (imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 20, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
