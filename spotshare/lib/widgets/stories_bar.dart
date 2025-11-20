import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';

const double story_size = 80;

class StoriesBar extends StatelessWidget {
  final List<Map<String, String>> stories; // { "name": "...", "image": "..." }

  const StoriesBar({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final story = stories[index];
          return Container(
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle de bordure
                    Container(
                      width: story_size + 14,
                      height: story_size + 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dGreen,
                          width: 3.5,
                        ),
                      ),
                    ),
                    // Image
                    Container(
                      width: story_size,
                      height: story_size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(story["image"]!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  story["name"]!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
