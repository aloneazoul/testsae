import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/pages/Publication/trip/create_trip_page.dart';
import 'package:spotshare/pages/Account/post_feed_page.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Account/login_page.dart';
import 'package:spotshare/pages/Account/trip_map_overlay.dart';
import 'package:spotshare/pages/Chat/chat_page.dart';
import 'package:spotshare/models/conversation.dart';
import 'package:spotshare/widgets/post_grid_item.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final PostService _postService = PostService();

  Map<String, dynamic>? _userData;
  List<dynamic> _myTrips = [];
  
  List<dynamic> _myPosts = [];
  List<dynamic> _myMemories = [];

  bool _viewingMemories = false;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followsMe = false;
  late TabController _tabController;

  StreamSubscription? _postUpdateSubscription;
  StreamSubscription? _postDeleteSubscription;

  bool get isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();

    _postUpdateSubscription = PostService.postUpdates.listen((updatedPost) {
      if (!mounted) return;
      _updatePostInList(_myPosts, updatedPost);
      _updatePostInList(_myMemories, updatedPost);
    });

    _postDeleteSubscription = PostService.postDeletions.listen((deletedId) {
      if (!mounted) return;
      setState(() {
        _myPosts.removeWhere((p) => p['post_id'].toString() == deletedId);
        _myMemories.removeWhere((p) => p['post_id'].toString() == deletedId);
      });
    });
  }

  void _updatePostInList(List<dynamic> list, dynamic updatedPost) {
    final index = list.indexWhere(
      (p) => p['post_id'].toString() == updatedPost.id,
    );
    if (index != -1) {
      setState(() {
        list[index]['is_liked'] = updatedPost.isLiked ? 1 : 0;
        list[index]['likes_count'] = updatedPost.likes;
        list[index]['comments_count'] = updatedPost.comments;
      });
    }
  }

  @override
  void dispose() {
    _postUpdateSubscription?.cancel();
    _postDeleteSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String? _getUserIdFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data.containsKey('user_id')) return data['user_id'].toString();
    if (data.containsKey('id')) return data['id'].toString();
    return null;
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      String targetId;

      if (isMyProfile) {
        final profile = await getMyProfile();
        
        if (profile == null) {
          if (mounted) _logout();
          return;
        }

        _userData = profile;
        targetId = _getUserIdFromData(_userData) ?? "";
      } else {
        targetId = widget.userId!;
      }

      if (targetId.isEmpty || targetId == "null") {
        throw Exception("ID utilisateur invalide");
      }

      final futures = await Future.wait([
        !isMyProfile ? getUserById(targetId) : Future.value(_userData),
        _tripService.getTripsByUser(targetId),
        _postService.getPostsByUser(targetId, type: "POST"),
        _postService.getPostsByUser(targetId, type: "MEMORY"),
      ]);

      if (mounted) {
        setState(() {
          _userData = futures[0] as Map<String, dynamic>?;
          _myTrips = futures[1] as List<dynamic>;
          _myPosts = futures[2] as List<dynamic>;
          _myMemories = futures[3] as List<dynamic>;

          if (_userData != null) {
            _isFollowing = _userData!['is_following'] == true;
            _followsMe = _userData!['follows_me'] == true;
          }

          _loading = false;
        });
      }
    } catch (e) {
      print("Erreur chargement profil: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    setState(() => _isFollowing = !_isFollowing);

    bool success;
    if (_isFollowing) {
      success = await followUser(widget.userId!);
    } else {
      success = await unfollowUser(widget.userId!);
    }

    if (!success) {
      setState(() => _isFollowing = !_isFollowing);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  void _navigateToChat() {
    if (_userData == null || widget.userId == null) return;
    final conversation = Conversation(
      id: widget.userId!,
      name: _userData!['username'] ?? _userData!['pseudo'] ?? "User",
      avatarUrl: _userData!['profile_picture'] ?? _userData!['img'] ?? '',
      messages: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversation: conversation,
          onSend: (String conversationId, String text) {},
        ),
      ),
    );
  }

  void _openTripOverlay(dynamic trip) {
    String myId = "0";
    if (_userData != null) {
      myId = _getUserIdFromData(_userData) ?? "0";
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TripMapOverlay(
            trip: trip,
            onClose: () => Navigator.of(context).pop(),
            userData: _userData!,
            currentLoggedUserId: myId,
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    await StorageService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: dGreen)),
      );
    }

    if (_userData == null) return _buildErrorState();

    String pseudo =
        _userData!['username'] ?? _userData!['pseudo'] ?? 'Utilisateur';
    String bio = _userData!['bio'] ?? '';
    String? avatarUrl = _userData!['profile_picture'] ?? _userData!['img'];

    int totalPosts = _myPosts.length + _myMemories.length;
    String nbPosts = (_userData!['posts_count'] ?? totalPosts).toString();
    String nbAbonnes = (_userData!['followers_count'] ?? 0).toString();
    String nbSuivis = (_userData!['following_count'] ?? 0).toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: !isMyProfile,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          pseudo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: _logout,
              tooltip: "Déconnexion",
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildProfileHeader(avatarUrl, nbPosts, nbAbonnes, nbSuivis),
          _buildBioSection(bio),

          isMyProfile ? _buildEditProfileButton() : _buildFollowButton(),

          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String? avatarUrl,
    String posts,
    String followers,
    String following,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white54)
                    : null,
              ),
              if (isMyProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_circle,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatColumn(posts, 'Posts'),
                _buildStatColumn(followers, 'Abonnés'),
                _buildStatColumn(following, 'Suivis'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: <Widget>[
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildBioSection(String bio) {
    if (bio.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          bio,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            'Modifier le profil',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[800] : dGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _isFollowing
                    ? 'Ne plus suivre'
                    : (_followsMe ? 'Suivre en retour' : 'Suivre'),
                style: TextStyle(
                  color: _isFollowing ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _navigateToChat,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Message',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: dGreen,
      labelColor: dGreen,
      unselectedLabelColor: Colors.grey,
      isScrollable: true,
      tabs: const <Widget>[
        Tab(text: 'Publications'),
        Tab(text: 'Voyages'),
        Tab(text: 'Brouillons'),
        Tab(text: 'Favoris'),
        Tab(text: 'Aimés'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: <Widget>[
        _buildPublicationTab(),
        _buildTripsGrid(),
        const Center(
          child: Text(
            'Vos brouillons',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
        const Center(
          child: Text(
            'Vos favoris',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
        const Center(
          child: Text(
            'Posts aimés',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicationTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("Posts", !_viewingMemories),
              const SizedBox(width: 20),
              Container(width: 1, height: 15, color: Colors.grey[800]),
              const SizedBox(width: 20),
              _buildFilterButton("Memories", _viewingMemories),
            ],
          ),
        ),
        Expanded(
          child: _buildPostsGrid(),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        setState(() {
          _viewingMemories = label == "Memories";
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    final displayList = _viewingMemories ? _myMemories : _myPosts;
    final emptyMessage = _viewingMemories ? "Aucun memory." : "Aucun post.";

    if (displayList.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
        childAspectRatio: 1.0, 
      ),
      itemCount: displayList.length,
      itemBuilder: (BuildContext context, int index) {
        final post = displayList[index];

        String? imageUrl;
        if (post['media_urls'] != null && post['media_urls'].isNotEmpty) {
          imageUrl = post['media_urls'].split(',')[0];
        }

        return FutureBuilder<List<dynamic>>(
          future: imageUrl == null
              ? _postService.getMediaTripPosts(post['post_id'])
              : null,
          builder: (context, snapshot) {
            bool isMultiple = false;

            if (imageUrl != null) {
              isMultiple = post['media_urls'].toString().contains(',');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              imageUrl = snapshot.data![0]['media_url'];
              isMultiple = snapshot.data!.length > 1;
            }

            return PostGridItem(
              imageUrl: imageUrl ?? "",
              isMultiple: isMultiple,
              onTap: () async {
                String myId = "0";
                if (_userData != null) {
                  myId = _getUserIdFromData(_userData) ?? "0";
                }

                final bool? shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostFeedPage(
                      postsRaw: displayList,
                      userData: _userData!,
                      initialPostId: post['post_id'].toString(),
                      currentLoggedUserId: myId,
                      // AJOUT CRITIQUE : On passe explicitement le type de feed
                      isMemoryFeed: _viewingMemories,
                    ),
                  ),
                );

                if (shouldRefresh == true) {
                  _loadAllData();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTripsGrid() {
    Widget content;
    if (_myTrips.isEmpty) {
      content = const Center(
        child: Text("Aucun voyage.", style: TextStyle(color: Colors.grey)),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.8,
          ),
          itemCount: _myTrips.length,
          itemBuilder: (BuildContext context, int index) {
            final trip = _myTrips[index];
            return TripGridItem(
              trip: trip,
              onTap: () => _openTripOverlay(trip),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        content,
        if (isMyProfile)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "add_trip_profile",
              backgroundColor: dGreen,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTripPage(),
                  ),
                );
                if (result == true) _loadAllData();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Impossible de charger le profil",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _logout, child: const Text("Retour")),
          ],
        ),
      ),
    );
  }
}

class TripGridItem extends StatefulWidget {
  final dynamic trip;
  final VoidCallback onTap;

  const TripGridItem({required this.trip, required this.onTap, super.key});

  @override
  State<TripGridItem> createState() => _TripGridItemState();
}

class _TripGridItemState extends State<TripGridItem> {
  bool _isHovering = false;

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [dGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.flight_takeoff, color: Colors.black26, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String tripTitle = widget.trip['trip_title'] ?? "Voyage sans nom";
    final String? bannerUrl = widget.trip['banner'];

    return MouseRegion(
      onEnter: (event) => _onHover(true),
      onExit: (event) => _onHover(false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerUrl != null && bannerUrl.isNotEmpty)
                      Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackImage(),
                      )
                    else
                      _buildFallbackImage(),

                    if (_isHovering)
                      Container(
                        color: Colors.black54,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0, bottom: 4.0),
              child: Text(
                tripTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}