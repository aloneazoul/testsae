import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/pages/Search/search_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';

class HomePage extends StatefulWidget {
  // ✅ On permet de passer une Key au constructeur
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState(); // Note: on enlève le underscore pour rendre le State public si besoin
}

// On rend la classe State publique (HomePageState au lieu de _HomePageState) 
// pour pouvoir utiliser le GlobalKey<HomePageState>
class HomePageState extends State<HomePage> {
  final PostService _postService = PostService();
  
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  // ✅ Méthode publique pour forcer le rafraîchissement
  Future<void> refreshFeed() async {
    await _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true); // Optionnel : montrer le chargement ou pas
    final rawData = await _postService.getDiscoveryFeed();
    
    if (mounted) {
      setState(() {
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFeed,
        child: ListView(
          children: [
            StoriesBar(stories: const [{"name": "Moi", "image": "https://picsum.photos/200"}]),
            const SizedBox(height: 10),
            if (_isLoading)
               const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
            else if (_posts.isEmpty)
               const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Aucun post pour le moment.")))
            else
               ..._posts.map((post) => PostCard(
                 post: post, 
                 isOwner: false,
               )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}