import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart'; // ✅ On utilise le modèle
import 'package:spotshare/pages/Search/search_page.dart';
import 'package:spotshare/services/post_service.dart'; // ✅ On utilise le service
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';

// 🗑️ SUPPRIME l'import de 'sample_data.dart' s'il est encore là !

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // On stocke une liste de VRAIS objets PostModel
  final PostService _postService = PostService();
  
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    // 1. Appel API
    final rawData = await _postService.getDiscoveryFeed();
    
    if (mounted) {
      setState(() {
        // 2. Utilisation du traducteur (fromJson)
        _posts = rawData.map((json) => PostModel.fromJson(json)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
          const SizedBox(width: 8), // Petite marge
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFeed, // Permet de recharger en tirant l'écran
        child: ListView(
          children: [
            // Stories (On garde ça statique pour l'instant)
            StoriesBar(
              stories: const [
                {"name": "Moi", "image": "https://picsum.photos/200"},
              ],
            ),
            
            const SizedBox(height: 10),

            // Gestion des états (Chargement / Vide / Rempli)
            if (_isLoading)
               const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
            else if (_posts.isEmpty)
               const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Aucun post pour le moment. Ajoutez des amis !")))
            else
               // Affichage de la liste
               ..._posts.map((post) => PostCard(
                 post: post, 
                 isOwner: false, // Ce n'est pas mon post, donc pas de menu supprimer
               )),
               
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}