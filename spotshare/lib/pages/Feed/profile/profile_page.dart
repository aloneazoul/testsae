import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'profile_post_page.dart';
import '../data/sample_data.dart';

class ProfilePage extends StatelessWidget {
  final String userName;

  ProfilePage({required this.userName});

  // Récupère tous les posts de cet utilisateur
  List<PostModel> getUserPosts() {
  List<PostModel> posts = sampleData.where((post) => post.userName == userName).toList();
  // Trier du plus récent au plus ancien
  posts.sort((a, b) => b.date.compareTo(a.date));
  return posts;
}


  @override
  Widget build(BuildContext context) {
    final userPosts = getUserPosts();

    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header profil
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  // Photo de profil
                  CircleAvatar(
  radius: 40,
  backgroundImage: NetworkImage(userPosts.isNotEmpty
      ? userPosts[0].profileImageUrl
      : 'https://picsum.photos/seed/default/50'), // fallback si pas de post
),

                  SizedBox(width: 16),
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(userPosts.length.toString(), style: TextStyle( fontWeight: FontWeight.bold)),
                            Text('Posts', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                        Column(
                          children: [
                            Text('123', style: TextStyle( fontWeight: FontWeight.bold)),
                            Text('Abonnés', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                        Column(
                          children: [
                            Text('150', style: TextStyle( fontWeight: FontWeight.bold)),
                            Text('Abonnements', style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bio de $userName. Passionné de Flutter et de mini Instagram!',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Grille des posts
            // Grille des posts
GridView.builder(
  physics: NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  itemCount: userPosts.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
  ),
  itemBuilder: (context, index) {
    final post = userPosts[index];
    return GestureDetector(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProfilePostPage(
        userPosts: userPosts,
        initialIndex: index,
      ),
    ),
  );
},


      child: Image.network(post.imageUrls[0], fit: BoxFit.cover),
    );
  },
),

          ],
        ),
      ),
    );
  }
}
