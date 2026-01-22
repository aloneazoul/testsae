import 'package:flutter/material.dart';
import 'package:spotshare/pages/Chat/conversations_page.dart';
import 'package:spotshare/pages/Feed/home_page.dart';
import 'package:spotshare/pages/Publication/post/Publication_page.dart';
import '../pages/Map/map_page.dart';
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

  final GlobalKey<HomePageState> _feedKey = GlobalKey<HomePageState>();

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _widgetOptions = [
      const MapPage(data: 1),
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

    if (index == 1) {
      _feedKey.currentState?.refreshFeed();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public_sharp),
            label: 'Carte',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
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
