// Dans spotshare/lib/pages/Chat/add_friend_page.dart

import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/services/user_service.dart'; // Import du service

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Liste des utilisateurs affichés
  List<dynamic> _usersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Au lancement, on cherche "rien" => l'API renvoie tous les users récents
    _performSearch("");
  }

  // Fonction centrale pour chercher
  void _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    // Appel au service
    final results = await searchUsers(query);
    
    if (mounted) {
      setState(() {
        _usersList = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("Ajouter des amis", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- BARRE DE RECHERCHE ---
            TextField(
              controller: _searchCtrl,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Rechercher un ami...",
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (val) {
                // À chaque lettre tapée, on relance la recherche API
                _performSearch(val);
              },
            ),

            const SizedBox(height: 20),

            // --- LISTE DES RÉSULTATS ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _usersList.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucun utilisateur trouvé",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _usersList.length,
                          itemBuilder: (context, index) {
                            final user = _usersList[index];
                            final String name = user['username'] ?? "Inconnu";
                            final String? photoUrl = user['profile_picture'];
                            final int userId = user['user_id'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.primaries[userId % Colors.primaries.length],
                                  backgroundImage: photoUrl != null 
                                      ? NetworkImage(photoUrl) 
                                      : null,
                                  child: photoUrl == null 
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : "?", 
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                trailing: ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                                  label: const Text(
                                    "Ajouter",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () {
                                    // Action vide pour le moment
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Ajout de $name (Simulation)"),
                                        backgroundColor: isDark ? Colors.grey[800] : Colors.black,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}