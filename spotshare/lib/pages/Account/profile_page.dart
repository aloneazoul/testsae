import 'package:flutter/material.dart';
import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/services/storage_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await getMyProfile();
    if (mounted) {
      setState(() {
        _userData = data;
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

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Erreur de chargement du profil"),
              ElevatedButton(
                onPressed: _logout,
                child: const Text("Se déconnecter"),
              ),
            ],
          ),
        ),
      );
    }

    String? imgUrl = _userData!['img'] as String?;

    String pseudo = _userData!['pseudo'] ?? 'Utilisateur';
    String email = _userData!['email'] ?? '';
    String phone = _userData!['phone'] ?? '';
    String birthDate = _userData!['birth_date'] ?? '';
    String gender = _userData!['gender'] ?? 'Homme';
    String bio = _userData!['bio'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(pseudo),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (imgUrl != null && imgUrl.isNotEmpty)
                  ? NetworkImage(imgUrl)
                  : null,
              child: (imgUrl == null || imgUrl.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              pseudo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("$email, $phone", style: TextStyle(color: Colors.grey[600])),
            Text(
              (gender == 'Femme' ? "Née le : " : "Né le : ") + birthDate,
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              "Biographie\n$bio",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),

            // Statistiques factices pour l'instant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("Posts", "0"),
                _buildStat("Abonnés", "120"),
                _buildStat("Suivi", "45"),
              ],
            ),
            const Divider(height: 40),
            const Center(child: Text("Mes publications s'afficheront ici.")),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
