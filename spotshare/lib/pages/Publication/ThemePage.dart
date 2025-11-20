// lib/pages/Feed/home_page.dart
import 'package:flutter/material.dart';

class ThemePage extends StatelessWidget {
  final VoidCallback? toggleTheme;

  const ThemePage({super.key, this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Changer de thème',
            onPressed: toggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Exemple de stories en haut
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                CircleAvatar(radius: 40, backgroundColor: Colors.green),
                SizedBox(width: 8),
                CircleAvatar(radius: 40, backgroundColor: Colors.blue),
                SizedBox(width: 8),
                CircleAvatar(radius: 40, backgroundColor: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exemple de posts
          const PostCard(
            username: 'Alice',
            content: 'Salut tout le monde !',
          ),
          const SizedBox(height: 16),
          const PostCard(
            username: 'Bob',
            content: 'Regardez ce super spot que j’ai trouvé !',
          ),
        ],
      ),
    );
  }
}

// Exemple de PostCard minimal pour test
class PostCard extends StatelessWidget {
  final String username;
  final String content;

  const PostCard({super.key, required this.username, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
