import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';

class StoriesBar extends StatelessWidget {
  // Liste renvoyée par getStoriesFeed
  // Structure: [{user_id: 1, username: "...", profile_picture: "...", is_mine: true, all_seen: true, stories: [...]}]
  final List<dynamic> stories; 
  final VoidCallback? onAddStoryTap;
  final Function(int index)? onStoryTap; // Callback quand on clique sur une bulle

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
          
          final bool isMine = group['is_mine'] == true;
          // Si c'est à moi, j'affiche ma photo. Si c'est un ami, sa photo.
          final String imageUrl = group['profile_picture'] ?? "";
          final String username = group['username'] ?? "Moi";
          final bool allSeen = group['all_seen'] ?? true;
          
          // Cas spécial : Si c'est ma bulle et que je n'ai pas de story, 
          // c'est souvent géré différemment (bouton +). 
          // Ici le backend ne renvoie "moi" que si j'ai posté.
          // Si vous voulez le bouton "+" permanent, il faut l'ajouter manuellement dans la liste côté HomePage.
          
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
    // Définition des couleurs du bord
    // Vert si nouveau, Gris si tout vu
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
            padding: const EdgeInsets.all(2.5), // Espace entre bordure et photo
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black, // Fond noir derrière la photo
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

        // Petit "+" si c'est moi et (optionnel) si je veux ajouter
        // Ici on peut décider d'afficher le "+" uniquement si c'est géré en amont
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