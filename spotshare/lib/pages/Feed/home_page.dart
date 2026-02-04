import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/pages/Search/search_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/story_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';
import 'package:spotshare/widgets/reel_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  late TabController _tabController;
  
  List<PostModel> _posts = [];
  List<PostModel> _memories = [];
  List<Map<String, dynamic>> _stories = [];

  bool _isLoading = true;
  StreamSubscription? _postSubscription;
  int _currentReelIndex = 0;
  
  // État pour savoir si on est sur l'onglet Feed (0) ou Memories (1)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Écouteur pour changer le style du header quand on change d'onglet
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _loadData();

    _postSubscription = PostService.postUpdates.listen((updatedPost) {
      _onPostUpdatedGlobally(updatedPost);
    });
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onPostUpdatedGlobally(PostModel updatedPost) {
    if (!mounted) return;
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) setState(() => _posts[index] = updatedPost);
    
    final indexMem = _memories.indexWhere((p) => p.id == updatedPost.id);
    if (indexMem != -1) setState(() => _memories[indexMem] = updatedPost);
  }

  Future<void> refreshFeed() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final feedFuture = _postService.getDiscoveryFeed(type: "POST");
      final memoriesFuture = _postService.getDiscoveryFeed(type: "MEMORY");
      final storiesFuture = _storyService.getStoriesFeed();
      final myProfileFuture = getMyProfile();

      final results = await Future.wait([
        feedFuture,
        memoriesFuture,
        storiesFuture,
        myProfileFuture,
      ]);

      if (mounted) {
        setState(() {
          _posts = (results[0] as List).map((json) => PostModel.fromJson(json)).where((p) => p.postType == "POST").toList();
          _memories = (results[1] as List).map((json) => PostModel.fromJson(json)).where((p) => p.postType == "MEMORY").toList();

          _stories.clear();
          String myPic = "";
          final myProfile = results[3] as Map<String, dynamic>?;
          if (myProfile != null) {
            myPic = myProfile['profile_picture'] ?? myProfile['img'] ?? "";
          }
          _stories.add({"name": "Moi", "image": myPic, "is_mine": true});

          for (var s in (results[2] as List)) {
            _stories.add({
              "name": s['username'] ?? "Ami",
              "image": s['profile_picture'] ?? "",
              "is_mine": false,
              "story_id": s['story_id'],
            });
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LE CONTENU (TabBarView)
          TabBarView(
            controller: _tabController,
            children: [
              _buildClassicFeed(), // Index 0
              _buildReelsFeed(),   // Index 1
            ],
          ),

          // 2. LE HEADER FLOTTANT (Dynamique)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              // CORRECTION : Fond NOIR si Feed, TRANSPARENT si Memories
              // Cela couvre la barre d'état (heure/batterie)
              color: _currentTabIndex == 0 ? Colors.black : Colors.transparent,
              
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // Dégradé uniquement si on est en mode Memories (pour lisibilité)
                  decoration: _currentTabIndex == 1 
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : null, // Pas de dégradé en mode Feed (déjà fond noir)
                  
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // A. Espace vide à gauche pour équilibrer
                      const SizedBox(width: 28), 

                      // B. Les Onglets au Centre
                      Expanded(
                        child: Center(
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicatorColor: Colors.white,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicatorWeight: 2,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white60,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                            tabs: const [
                              Tab(text: "Feed"),
                              Tab(text: "Memories"),
                            ],
                          ),
                        ),
                      ),

                      // C. La Loupe à Droite
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                        child: const Icon(
                          Icons.search, 
                          color: Colors.white, 
                          size: 28,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Onglet 1 : Feed Classique
  Widget _buildClassicFeed() {
    return RefreshIndicator(
      onRefresh: refreshFeed,
      color: Colors.white,
      backgroundColor: Colors.grey[900],
      child: ListView(
        // Padding important en haut : Hauteur estimée du header + SafeArea
        // On met 120 pour être sûr que le premier item (Stories) ne soit pas caché
        padding: const EdgeInsets.only(top: 120, bottom: 80), 
        children: [
          StoriesBar(
            stories: _stories,
            onAddStoryTap: () => print("Add Story"),
          ),
          
          const Divider(color: Colors.white10, height: 20),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: Colors.white)))
          else if (_posts.isEmpty)
             const Padding(padding: EdgeInsets.all(50), child: Center(child: Text("Aucun post.", style: TextStyle(color: Colors.grey))))
          else
            ..._posts.map((post) => PostCard(post: post, isOwner: false)),
        ],
      ),
    );
  }

  // Onglet 2 : Memories (Plein écran)
  Widget _buildReelsFeed() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_memories.isEmpty) return const Center(child: Text("Aucun memory", style: TextStyle(color: Colors.white)));

    // Pas de padding ici, on veut du plein écran total
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _memories.length,
      onPageChanged: (index) => setState(() => _currentReelIndex = index),
      itemBuilder: (context, index) {
        return ReelItem(
          post: _memories[index],
          isVisible: index == _currentReelIndex,
        );
      },
    );
  }
}