import 'package:flutter/material.dart';
import 'package:spotshare/pages/Chat/conversations_page.dart';
import 'package:spotshare/pages/Feed/home_page.dart';
import 'package:spotshare/pages/Publication/list_trips_page.dart';
import '../pages/Map/map_page.dart';
import 'package:spotshare/pages/Chat/data/sample_data.dart';
import '../pages/Account/profile_page.dart';

class BottomNavigationBarExample extends StatefulWidget {
  final VoidCallback? toggleTheme;
  const BottomNavigationBarExample({super.key, this.toggleTheme});

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  int _selectedIndex = 1;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      const MapPage(),
      HomePage(),
      MesVoyagesPage(),
      ConversationsPage(conversations: sampleConversations()),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public_sharp),
            label: 'Carte',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Publier'),
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
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
