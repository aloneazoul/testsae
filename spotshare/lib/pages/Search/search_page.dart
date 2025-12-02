import 'package:flutter/material.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/pages/Account/profile_page.dart';
import 'package:spotshare/utils/constants.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Charge les utilisateurs par défaut dès l'ouverture de la page
    _onSearchChanged("");
  }

  void _onSearchChanged(String query) async {
    // On ne vide pas la liste si c'est vide, on relance la recherche globale
    // pour avoir les suggestions par défaut
    
    setState(() => _isLoading = true);

    // Appel au service
    final users = await searchUsers(query);

    if (mounted) {
      setState(() {
        _results = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true, 
            textAlignVertical: TextAlignVertical.center, // ✅ Centre verticalement le curseur/texte
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              // ✅ Ajustement crucial pour centrer le texte dans le Container de 40px
              contentPadding: EdgeInsets.zero, 
              isDense: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dGreen))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                final String status = user['status'] ?? "";
                
                // Construction du sous-titre
                String subtitleText = "@${user['username']}";
                if (status.isNotEmpty) {
                  subtitleText += " • $status";
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user['profile_picture'] != null && user['profile_picture'] != "")
                        ? NetworkImage(user['profile_picture'])
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: (user['profile_picture'] == null || user['profile_picture'] == "")
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    user['username'],
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: TextStyle(
                      // Vert si c'est "ami(e)s" ou "vous suit", sinon Gris (pour "Suivi" ou vide)
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    // Navigation vers le profil universel
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          userId: user['user_id'].toString(),
                        ),
                      ),
                    ).then((_) {
                      // Au retour, on recharge la liste pour mettre à jour les statuts (ex: si on a follow)
                      _onSearchChanged(_searchCtrl.text);
                    });
                  },
                );
              },
            ),
    );
  }
}