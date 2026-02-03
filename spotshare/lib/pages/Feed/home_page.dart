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
import 'package:spotshare/pages/Publication/post/Publication_page.dart';
import 'package:spotshare/pages/Feed/story_player_page.dart';

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
  List<dynamic> _stories = [];

  bool _isLoading = true;
  StreamSubscription? _postSubscription;
  int _currentReelIndex = 0;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
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
          
          _stories = results[2] as List<dynamic>;

          bool meInList = false;
          for (var s in _stories) {
            if (s['is_mine'] == true) {
              meInList = true;
              break;
            }
          }

          if (!meInList) {
             final myProfile = results[3] as Map<String, dynamic>?;
             String myPic = "";
             String myName = "Moi";
             if (myProfile != null) {
               myPic = myProfile['profile_picture'] ?? myProfile['img'] ?? "";
               myName = myProfile['username'] ?? "Moi";
             }
             
             _stories.insert(0, {
               "user_id": 0,
               "username": myName,
               "profile_picture": myPic,
               "is_mine": true,
               "all_seen": true,
               "stories": []
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

  void _goToCreateStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PublishPage(returnIndex: 1),
      ),
    ).then((_) => refreshFeed());
  }

  void _openStory(List<dynamic> userStories, int index, Map<String, dynamic> groupData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryPlayerPage(
          stories: userStories, 
          initialIndex: index,
          username: groupData['username'] ?? "Utilisateur",
          userImage: groupData['profile_picture'] ?? "",
          isMine: groupData['is_mine'] == true,
        ),
      ),
    ).then((_) => refreshFeed()); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildClassicFeed(),
              _buildReelsFeed(),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: _currentTabIndex == 0 ? Colors.black : Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: _currentTabIndex == 1 
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 28), 
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

  Widget _buildClassicFeed() {
    return RefreshIndicator(
      onRefresh: refreshFeed,
      color: Colors.white,
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: const EdgeInsets.only(top: 120, bottom: 80), 
        children: [
          StoriesBar(
            stories: _stories,
            onAddStoryTap: _goToCreateStory,
            onStoryTap: (index) {
                final group = _stories[index];
                final bool isMine = group['is_mine'] == true;
                final List<dynamic> stories = group['stories'] ?? [];

                if (isMine && stories.isEmpty) {
                  _goToCreateStory();
                } else if (stories.isNotEmpty) {
                  int firstUnseenIndex = 0;
                  for(int i=0; i<stories.length; i++) {
                    if(stories[i]['is_viewed'] == false) {
                      firstUnseenIndex = i;
                      break;
                    }
                  }
                  _openStory(stories, firstUnseenIndex, group);
                }
            },
          ),
          
          const Divider(color: Colors.white10, height: 20),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: Colors.white)))
          else if (_posts.isEmpty)
             const Padding(padding: EdgeInsets.all(50), child: Center(child: Text("Aucun post.", style: TextStyle(color: Colors.grey))))
          else
            ..._posts.map((post) {
              // --- LIEN STORY <-> POST ---
              Map<String, dynamic>? storyGroup;
              try {
                storyGroup = _stories.firstWhere(
                  (s) => s['user_id'].toString() == post.userId,
                  orElse: () => null,
                );
              } catch (e) {
                storyGroup = null;
              }

              return PostCard(
                post: post, 
                isOwner: false,
                storyGroup: storyGroup, // Passage de l'info
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReelsFeed() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_memories.isEmpty) return const Center(child: Text("Aucun memory", style: TextStyle(color: Colors.white)));

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