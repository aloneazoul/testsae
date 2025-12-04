import 'package:flutter/material.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/pages/Publication/trip/create_trip_page.dart';
import 'package:spotshare/pages/Account/post_feed_page.dart';
import 'package:spotshare/utils/constants.dart';
import 'login_page.dart';
import 'package:spotshare/pages/Account/trip_map_overlay.dart';

// --- IMPORTS POUR LE CHAT ---
import 'package:spotshare/pages/Chat/chat_page.dart';
import 'package:spotshare/models/conversation.dart';

// Import des widgets réutilisables
import 'package:spotshare/widgets/post_grid_item.dart';
import 'package:spotshare/widgets/trip_card_item.dart';
import 'package:spotshare/widgets/sliver_header_delegate.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // ID optionnel pour le mode "Visiteur"

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();

  Map<String, dynamic>? _userData;
  List<dynamic> _myTrips = [];

  bool _loading = true;
  bool _isFollowing = false; 
  bool _followsMe = false;   
  late TabController _tabController;

  List<dynamic> _myPosts = [];
  final PostService _postService = PostService();

  // Helper pour savoir si c'est MON profil
  bool get isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    Future<Map<String, dynamic>?> profileFuture;
    Future<List<dynamic>> tripsFuture;
    Future<List<dynamic>> postsFuture;

    if (isMyProfile) {
      profileFuture = getMyProfile();
      tripsFuture = _tripService.getMyTrips();
      postsFuture = _postService.getPosts();
    } else {
      profileFuture = getUserById(widget.userId!);
      tripsFuture = _tripService.getTripsByUser(widget.userId!);
      postsFuture = _postService.getPostsByUser(widget.userId!);
    }

    final results = await Future.wait([
      profileFuture,
      tripsFuture,
      postsFuture,
    ]);

    if (mounted) {
      setState(() {
        _userData = results[0] as Map<String, dynamic>?;
        _myTrips = results[1] as List<dynamic>;
        _myPosts = results[2] as List<dynamic>; 
        
        // Récupération des états de relation (Follow)
        if (_userData != null) {
          if (_userData!.containsKey('is_following')) {
            _isFollowing = _userData!['is_following'] == true;
          } else {
            _isFollowing = false;
          }

          if (_userData!.containsKey('follows_me')) {
            _followsMe = _userData!['follows_me'] == true;
          } else {
            _followsMe = false;
          }
        }
        
        _loading = false;
      });
    }
  }

  // --- ACTION : SUIVRE / NE PLUS SUIVRE ---
  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;

    setState(() {
      _isFollowing = !_isFollowing;
    });

    bool success;
    if (_isFollowing) {
      success = await followUser(widget.userId!);
    } else {
      success = await unfollowUser(widget.userId!);
    }

    if (!success) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion")));
    }
  }

  // --- ACTION : OUVRIR LE CHAT (Version Corrigée) ---
  void _navigateToChat() {
    if (_userData == null || widget.userId == null) return;

    // On passe l'ID utilisateur directement comme ID de conversation
    // On met '' pour l'avatarUrl si null pour éviter le crash (géré par le CircleAvatar plus loin)
    final conversation = Conversation(
      id: widget.userId!, 
      name: _userData!['pseudo'] ?? "User",
      avatarUrl: _userData!['img'] ?? '', 
      messages: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversation: conversation,
          onSend: (targetId, text) {
            // Callback optionnel
          },
        ),
      ),
    );
  }

  // --- ACTION : OUVRIR LA CARTE DU VOYAGE (Overlay) ---
  void _openTripOverlay(dynamic trip) {
    // Essaie d'extraire un centre depuis le trip
    double defaultLng = 2.2945, defaultLat = 48.8584; // Tour Eiffel par défaut
    double lng = defaultLng;
    double lat = defaultLat;

    try {
      if (trip == null) {
        // keep defaults
      } else if (trip['coords'] is Map) {
        final c = trip['coords'];
        lng = (c['lng'] ?? c['lon'] ?? c['longitude'] ?? c['0'] ?? lng).toDouble();
        lat = (c['lat'] ?? c['latitude'] ?? c['1'] ?? lat).toDouble();
      } else if (trip['center'] is List && trip['center'].length >= 2) {
        lng = (trip['center'][0] as num).toDouble();
        lat = (trip['center'][1] as num).toDouble();
      } else if (trip['lat'] != null && trip['lng'] != null) {
        lng = (trip['lng'] as num).toDouble();
        lat = (trip['lat'] as num).toDouble();
      } else if (trip['location'] is Map) {
        final loc = trip['location'];
        lng = (loc['lng'] ?? loc['lon'] ?? lng).toDouble();
        lat = (loc['lat'] ?? loc['latitude'] ?? lat).toDouble();
      }
    } catch (_) {
      lng = defaultLng;
      lat = defaultLat;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // important: laisse voir le dessous
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          final String myId = _userData!['id']?.toString() ?? _userData!['user_id']?.toString() ?? "0";
          return TripMapOverlay(
            trip: trip,
            onClose: () => Navigator.of(context).pop(),
            userData: _userData!,
            currentLoggedUserId: myId,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    if (_userData == null) return _buildErrorState();

    String pseudo = _userData!['pseudo'] ?? 'Utilisateur';
    String? imgUrl = _userData!['img'];
    String bio = _userData!['bio'] ?? '';

    String nbPosts = (_userData!['posts_count'] ?? 0).toString();
    String nbAbonnes = (_userData!['followers_count'] ?? 0).toString(); 
    String nbSuivis = (_userData!['following_count'] ?? 0).toString();

    String followButtonText = "Suivre";
    if (_isFollowing) {
      followButtonText = "Ne plus suivre";
    } else if (_followsMe) {
      followButtonText = "Suivre en retour";
    }

    return Scaffold(
      backgroundColor: Colors.black, // ⚫️ Fond TikTok
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.black,
              title: Text(pseudo, style: const TextStyle(color: Colors.white)),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (isMyProfile)
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.red),
                    onPressed: _logout,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[800], // ⚫️ Style TikTok
                          backgroundImage: (imgUrl != null && imgUrl.isNotEmpty)
                              ? NetworkImage(imgUrl)
                              : null,
                          child: (imgUrl == null || imgUrl.isEmpty)
                              ? const Icon(Icons.person, size: 40, color: Colors.white54)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("Posts", nbPosts),
                              _buildStatItem("Abonnés", nbAbonnes),
                              _buildStatItem("Suivi", nbSuivis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pseudo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          bio,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // BOUTONS ACTIONS (Message / Suivre)
                    if (!isMyProfile) ...[
                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing ? Colors.grey[800] : dGreen,
                                  foregroundColor: _isFollowing ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: _isFollowing ? const BorderSide(width: 0) : BorderSide.none,
                                ),
                                child: Text(
                                  followButtonText,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _navigateToChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Message", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                  ],
                ),
              ),
            ),

            SliverPersistentHeader(
              delegate: SliverHeaderDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: dGreen,
                  labelColor: dGreen,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "Publications"),
                    Tab(text: "Voyages"),
                    Tab(text: "Brouillons"),
                    Tab(text: "Favoris"),
                    Tab(text: "Aimés"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPublicationsTab(),
            _buildVoyagesTab(),
            _buildPlaceholderTab("Vos brouillons"),
            _buildPlaceholderTab("Vos favoris"),
            _buildPlaceholderTab("Posts aimés"),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationsTab() {
    if (_myPosts.isEmpty) {
      return const Center(child: Text("Aucune publication.", style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        final int postId = post['post_id'];
        return FutureBuilder<List<dynamic>>(
          future: _postService.getMediaTripPosts(postId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
              return Container(color: Colors.grey[900], child: const Icon(Icons.image, color: Colors.white24));
            }
            final List<dynamic> mediaList = snapshot.data!;
            final String? firstImageUrl = mediaList[0]['media_url'];
            final bool isMultiple = mediaList.length > 1;

            if (firstImageUrl == null || firstImageUrl.isEmpty) return Container(color: Colors.grey[900]);

            return PostGridItem(
              imageUrl: firstImageUrl,
              isMultiple: isMultiple,
              onTap: () async {
                if (_userData != null) {
                  final String myId = isMyProfile ? (_userData!['id']?.toString() ?? _userData!['user_id']?.toString() ?? "0") : "0";
                  final bool? shouldRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostFeedPage(
                        postsRaw: _myPosts,
                        userData: _userData!,
                        initialIndex: index,
                        currentLoggedUserId: myId,
                      ),
                    ),
                  );
                  if (shouldRefresh == true) _loadAllData(); 
                }
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildVoyagesTab() {
    return Stack(
      children: [
        if (_myTrips.isEmpty)
          _buildPlaceholderTab("Aucun voyage créé")
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: _myTrips.length,
            itemBuilder: (context, index) {
              final trip = _myTrips[index];
              return TripCardItem(
                trip: trip,
                onTap: () => _openTripOverlay(trip), // Utilisation de l'overlay de carte
              );
            },
          ),
        if (isMyProfile)
          Positioned(
            bottom: 16, right: 16,
            child: FloatingActionButton(
              heroTag: "add_trip_profile",
              backgroundColor: dGreen,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTripPage()));
                if (result == true) _loadAllData();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String message) {
    return Center(child: Text(message, style: const TextStyle(color: Colors.grey)));
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.grey)),
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
            const Text("Erreur profil", style: TextStyle(color: Colors.white)),
            if (isMyProfile)
              ElevatedButton(onPressed: _logout, child: const Text("Déconnexion")),
          ],
        ),
      ),
    );
  }
}