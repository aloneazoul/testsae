import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/pages/Search/search_page.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/story_service.dart';
import 'package:spotshare/widgets/post_card.dart';
import 'package:spotshare/widgets/stories_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  List<PostModel> _posts = [];
  List<Map<String, dynamic>> _stories = [];

  bool _isLoading = true;
  StreamSubscription? _postSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();

    _postSubscription = PostService.postUpdates.listen((updatedPost) {
      _onPostUpdatedGlobally(updatedPost);
    });
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    super.dispose();
  }

  void _onPostUpdatedGlobally(PostModel updatedPost) {
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1 && mounted) {
      setState(() {
        _posts[index] = updatedPost;
      });
    }
  }

  Future<void> refreshFeed() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final feedFuture = _postService.getDiscoveryFeed();

    final storiesFuture = _storyService.getStoriesFeed();

    final myProfileFuture = getMyProfile();

    final results = await Future.wait([
      feedFuture,
      storiesFuture,
      myProfileFuture,
    ]);

    final feedData = results[0] as List<dynamic>;
    final storiesData = results[1] as List<dynamic>;
    final myProfile = results[2] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        _posts = feedData.map((json) => PostModel.fromJson(json)).toList();

        _stories.clear();

        String myPic = "";
        if (myProfile != null) {
          myPic = myProfile['profile_picture'] ?? myProfile['img'] ?? "";
        }
        _stories.add({"name": "Votre story", "image": myPic, "is_mine": true});

        for (var s in storiesData) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpotShare',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshFeed,
        child: ListView(
          children: [
            StoriesBar(
              stories: _stories,
              onAddStoryTap: () {
                print("Ajouter une story !");
              },
            ),

            const Divider(color: Colors.white10, height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_posts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Text("Aucun post pour le moment."),
                ),
              )
            else
              ..._posts.map((post) => PostCard(post: post, isOwner: false)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
