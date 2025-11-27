import 'package:flutter/material.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/post_service.dart';

import 'package:spotshare/utils/constants.dart';
import 'login_page.dart';

// Import des nouveaux widgets réutilisables
import 'package:spotshare/widgets/post_grid_item.dart';
import 'package:spotshare/widgets/trip_card_item.dart';
import 'package:spotshare/widgets/sliver_header_delegate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  
  Map<String, dynamic>? _userData;
  List<dynamic> _myTrips = [];
  
  bool _loading = true;
  late TabController _tabController;

  List<dynamic> _myPosts = []; 
  final PostService _postService = PostService();

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
    final profileFuture = getMyProfile();
    final tripsFuture = _tripService.getMyTrips();
    final postsFuture = _postService.getPosts();

    final results = await Future.wait([profileFuture, tripsFuture, postsFuture]);

    if (mounted) {
      setState(() {
        _userData = results[0] as Map<String, dynamic>?;
        _myTrips = results[1] as List<dynamic>;
        _myPosts = results[2] as List<dynamic>; // <--- Stockage des posts
        _loading = false;
      });
    }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) return _buildErrorState();

    String pseudo = _userData!['pseudo'] ?? 'Utilisateur';
    String? imgUrl = _userData!['img'];
    String bio = _userData!['bio'] ?? '';
    
    String nbPosts = "0"; 
    String nbAbonnes = "120";
    String nbSuivis = "45";

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.black,
              title: Text(pseudo),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
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
                          backgroundColor: Colors.grey[800],
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    if (bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(bio, style: const TextStyle(color: Colors.white70)),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Utilisation du widget délégué importé
            SliverPersistentHeader(
              delegate: SliverHeaderDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: dGreen,
                  labelColor: dGreen,
                  unselectedLabelColor: Colors.grey,
                  // On garde tes onglets texte qui fonctionnaient bien
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
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        final postId = post['post_id'];

        // Changement du type : On attend une Map<String, dynamic>?
        return FutureBuilder<Map<String, dynamic>?>(
          future: _postService.getFirstMediaTripPosts(postId),
          builder: (context, snapshot) {
            
            // 1. Si chargement ou pas de données -> Carré gris
            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                color: Colors.grey[900],
                child: const Icon(Icons.image, color: Colors.white24),
              );
            }

            // 2. Récupération de l'URL dans la Map
            // Assure-toi que la clé renvoyée par ton API est bien 'media_url'
            final mediaData = snapshot.data!;
            final String? imageUrl = mediaData['media_url']; 

            if (imageUrl == null || imageUrl.isEmpty) {
               return Container(color: Colors.grey[900]);
            }

            // 3. Affichage de l'image
            return PostGridItem(
              imageUrl: imageUrl,
              onTap: () {
                print("Ouvrir post $postId");
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVoyagesTab() {
    if (_myTrips.isEmpty) {
      return _buildPlaceholderTab("Aucun voyage créé");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTrips.length,
      itemBuilder: (context, index) {
        final trip = _myTrips[index];
        // Utilisation du widget importé TripCardItem
        return TripCardItem(
          trip: trip,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ouverture de la carte..."),
                backgroundColor: dGreen,
                duration: Duration(seconds: 1),
              ),
            );
          },
        );
      },
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
            ElevatedButton(onPressed: _logout, child: const Text("Déconnexion")),
          ],
        ),
      ),
    );
  }
}