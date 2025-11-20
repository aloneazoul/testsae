import 'package:flutter/material.dart';
import 'widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';
import 'data/sample_data.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Trier sampleData du plus récent au plus ancien
    final sortedPosts = List.from(sampleData)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Créer une map pour ne garder qu'un post par utilisateur
    final latestPosts = <String, dynamic>{};
    for (var post in sortedPosts) {
      if (!latestPosts.containsKey(post.userName)) {
        latestPosts[post.userName] = post;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // supprime le filtre
        shadowColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          StoriesBar(
            stories: [
              {"name": "Alone", "image": "https://picsum.photos/seed/alone/200"},
              {"name": "Emma", "image": "https://picsum.photos/seed/emma/200"},
              {"name": "Lucas", "image": "https://picsum.photos/seed/lucas/200"},
              {"name": "Zoé", "image": "https://picsum.photos/seed/zoe/200"},
              {"name": "Léa", "image": "https://picsum.photos/seed/lea/200"},
            ],
          ),
          const SizedBox(height: 10),
          // Afficher les posts les plus récents par utilisateur
          ...latestPosts.values.map((p) => PostCard(post: p)),
        ],
      ),
    );
  }
}
