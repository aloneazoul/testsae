import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/models/story_model.dart'; // Import ajouté

class StoriesBar extends StatelessWidget {
  // Liste typée UserStoryGroup
  final List<UserStoryGroup> stories; 
  final VoidCallback? onAddStoryTap;
  final Function(int index)? onStoryTap;

  const StoriesBar({
    Key? key,
    required this.stories,
    this.onAddStoryTap,
    this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final group = stories[index];
          
          final bool isMine = group.isMine;
          final String imageUrl = group.profilePicture ?? "";
          final String username = group.username;
          
          // Si allSeen est True, c'est gris. Si False (non vu), c'est vert.
          final bool allSeen = group.allSeen;
          
          return GestureDetector(
            onTap: () {
              if (onStoryTap != null) {
                onStoryTap!(index);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 12 : 8, right: 8),
              child: Column(
                children: [
                  _buildAvatarCircle(context, imageUrl, isMine, allSeen),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      isMine ? "Votre story" : username,
                      style: TextStyle(
                        // Texte gris si tout vu, blanc sinon (pour ressortir)
                        color: allSeen ? Colors.grey : Colors.white,
                        fontSize: 12,
                        fontWeight: allSeen ? FontWeight.normal : FontWeight.bold
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
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
    bool allSeen,
  ) {
    // Vert si nouveau (allSeen == false), Gris si tout vu
    final List<Color> borderColors = allSeen 
        ? [Colors.grey[700]!, Colors.grey[600]!]
        : [dGreen, const Color(0xFF2E7D32)];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle dégradé (Bordure)
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: borderColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.5), 
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black, 
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ),

        if (isMine)
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
}