import 'package:flutter/material.dart';
import 'package:spotshare/pages/Chat/conversations_page.dart';
import 'package:spotshare/pages/Feed/home_page.dart';
import 'package:spotshare/pages/Publication/post/Publication_page.dart';
import '../pages/Map/map_page.dart';
import 'package:spotshare/pages/Chat/data/sample_data.dart';
import '../pages/Account/profile_page.dart';
import 'package:spotshare/utils/constants.dart';

class BottomNavigationBarExample extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final int initialIndex;

  const BottomNavigationBarExample({
    super.key,
    this.toggleTheme,
    this.initialIndex = 1,
  });

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  late int _selectedIndex;
  
  // 🔥 1. Création de la télécommande pour le Feed
  final GlobalKey<HomePageState> _feedKey = GlobalKey<HomePageState>();
  
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _widgetOptions = [
      const MapPage(data: 1),
      // 🔥 2. On branche la télécommande sur la HomePage
      HomePage(key: _feedKey),
      const SizedBox(), 
      ConversationsPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PublishPage()),
      );
      return;
    }

    // 🔥 3. Si on clique sur le Feed (Index 1), on force le rechargement
    if (index == 1) {
       // On vérifie si on était déjà sur le feed pour scroller en haut, 
       // ou si on vient d'arriver pour rafraîchir.
       // Ici, on rafraîchit dans tous les cas quand on clique dessus.
       _feedKey.currentState?.refreshFeed();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack préserve l'état des pages (ne les détruit pas quand on change d'onglet)
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,

        // --- PARAMÈTRES DE STYLE ---
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 30, // Icônes plus grosses (Standard ~24)

        // ---------------------------
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public_sharp),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), 
            label: 'Feed'
          ),

          // Bouton central encore plus gros pour ressortir
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 48),
            label: 'Publier',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.messenger),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_sharp),
            label: 'Compte',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: dGreen,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}