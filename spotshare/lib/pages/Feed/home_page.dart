import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/models/story_model.dart'; // Import du modèle
import 'package:spotshare/pages/Search/search_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/story_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';
import 'package:spotshare/widgets/reel_item.dart';
import 'package:spotshare/pages/Publication/post/Publication_page.dart';
import 'package:spotshare/pages/Feed/story_player_page.dart';
import 'package:spotshare/utils/route_observer.dart';

class HomePage extends StatefulWidget {
  final Function(bool)? onPageVisibilityChanged;

  const HomePage({Key? key, this.onPageVisibilityChanged}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  late TabController _tabController;

  List<PostModel> _posts = [];
  List<PostModel> _memories = [];

  // CORRECTION : Typage fort ici
  List<UserStoryGroup> _stories = [];

  bool _isLoading = true;
  StreamSubscription? _postSubscription;
  int _currentReelIndex = 0;
  int _currentTabIndex = 0;

  // Pour tracker quel tab est actif et contrôler les vidéos
  bool _isReelsFeedVisible = false;
  bool _isPageVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _isReelsFeedVisible = _currentTabIndex == 1;
        });
      }
    });

    _loadData();

    _postSubscription = PostService.postUpdates.listen((updatedPost) {
      _onPostUpdatedGlobally(updatedPost);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(() => _isPageVisible = false);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isPageVisible = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _postSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // RouteAware callbacks - called when another route covers/un-covers this one
  @override
  void didPushNext() {
    // Another route was pushed above this one -> not visible
    if (mounted) setState(() => _isPageVisible = false);
    // Notify global listeners that feed is not visible
    try {
      feedPageVisible.value = false;
    } catch (_) {}
    super.didPushNext();
  }

  @override
  void didPopNext() {
    // Returned to this route -> visible again
    if (mounted) setState(() => _isPageVisible = true);
    // Notify global listeners that feed is visible
    try {
      feedPageVisible.value = true;
    } catch (_) {}
    super.didPopNext();
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

  void setPageVisibility(bool isVisible) {
    if (mounted) {
      setState(() {
        _isPageVisible = isVisible;
      });
    }
    // Update global notifier as well
    try {
      feedPageVisible.value = isVisible;
    } catch (_) {}
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final feedFuture = _postService.getDiscoveryFeed(type: "POST");
      final memoriesFuture = _postService.getDiscoveryFeed(type: "MEMORY");
      // Le service retourne maintenant Future<List<UserStoryGroup>>
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
          _posts = (results[0] as List)
              .map((json) => PostModel.fromJson(json))
              .where((p) => p.postType == "POST")
              .toList();
          _memories = (results[1] as List)
              .map((json) => PostModel.fromJson(json))
              .where((p) => p.postType == "MEMORY")
              .toList();

          // Casting correct
          _stories = results[2] as List<UserStoryGroup>;

          // Vérification : est-ce que je suis dans la liste ?
          bool meInList = _stories.any((s) => s.isMine);

          if (!meInList) {
            final myProfile = results[3] as Map<String, dynamic>?;
            String myPic = "";
            String myName = "Moi";
            int myId = 0;

            if (myProfile != null) {
              myPic = myProfile['profile_picture'] ?? myProfile['img'] ?? "";
              myName = myProfile['username'] ?? "Moi";
              myId = myProfile['user_id'] is int
                  ? myProfile['user_id']
                  : int.tryParse(myProfile['user_id'].toString()) ?? 0;
            }

            // CORRECTION : Insertion d'un Objet UserStoryGroup, pas d'une Map
            _stories.insert(
              0,
              UserStoryGroup(
                userId: myId,
                username: myName,
                profilePicture: myPic,
                isMine: true,
                allSeen: true,
                stories: [],
              ),
            );
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

  // CORRECTION : Paramètres typés
  void _openStory(
    List<StoryItem> userStories,
    int index,
    UserStoryGroup group,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryPlayerPage(
          stories: userStories,
          initialIndex: index,
          username: group.username,
          userImage: group.profilePicture ?? "",
          isMine: group.isMine,
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
            children: [_buildClassicFeed(), _buildReelsFeed()],
          ),

          // ... (Le reste du header reste identique, je ne le répète pas pour abréger, garde ton code existant ici) ...
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: _currentTabIndex == 0 ? Colors.black : Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                            tabs: const [
                              Tab(text: "Feed"),
                              Tab(text: "Memories"),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchPage()),
                        ),
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
          // StoriesBar accepte maintenant List<UserStoryGroup> -> Ça matche !
          StoriesBar(
            stories: _stories,
            onAddStoryTap: _goToCreateStory,
            onStoryTap: (index) {
              final group = _stories[index];

              if (group.isMine && group.stories.isEmpty) {
                _goToCreateStory();
              } else if (group.stories.isNotEmpty) {
                int firstUnseenIndex = 0;
                for (int i = 0; i < group.stories.length; i++) {
                  // Utilisation de la propriété .isViewed
                  if (group.stories[i].isViewed == false) {
                    firstUnseenIndex = i;
                    break;
                  }
                }
                _openStory(group.stories, firstUnseenIndex, group);
              }
            },
          ),

          const Divider(color: Colors.white10, height: 20),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: Text(
                  "Aucun post.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._posts.map((post) {
              // --- LIEN STORY <-> POST ---
              // On cherche le groupe correspondant à l'utilisateur du post
              UserStoryGroup? storyGroup;
              try {
                storyGroup = _stories.firstWhere(
                  (s) => s.userId.toString() == post.userId,
                );
              } catch (e) {
                storyGroup = null;
              }

              // Note: Si PostCard attend une Map pour storyGroup, il faudra l'adapter aussi
              // Mais ici on passe un UserStoryGroup? si tu as adapté PostCard, sinon convertis-le en Map temporairement si besoin.
              // Le mieux est de laisser storyGroup à null si PostCard n'est pas adapté, ou de passer l'objet.

              return PostCard(
                post: post,
                isOwner: false,
                // storyGroup: storyGroup, // Décommente si PostCard gère UserStoryGroup
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReelsFeed() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    if (_memories.isEmpty)
      return const Center(
        child: Text("Aucun memory", style: TextStyle(color: Colors.white)),
      );

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _memories.length,
      onPageChanged: (index) => setState(() => _currentReelIndex = index),
      itemBuilder: (context, index) {
        return ReelItem(
          post: _memories[index],
          isVisible:
              _isPageVisible &&
              _isReelsFeedVisible &&
              index == _currentReelIndex,
        );
      },
    );
  }
}
