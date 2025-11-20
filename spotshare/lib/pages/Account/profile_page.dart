import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final String pseudo;
  final String? profilePictureUrl;

  const ProfilePage({
    super.key,
    required this.email,
    required this.pseudo,
    this.profilePictureUrl,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _pseudoCtrl = TextEditingController();
  File? _selectedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pseudoCtrl.text = widget.pseudo;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _selectedImage = File(result.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);

    // 👉 Ici tu appelles l’API : UpdatePseudo, UpdateProfilePicture, etc.
    // Exemple :
    // await UpdateUserProfile(_pseudoCtrl.text, _selectedImage);

    await Future.delayed(const Duration(milliseconds: 800)); // Pour simuler

    setState(() => _saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profil mis à jour !")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Mon Profil"),
      ),
      body: Center(
        child: Card(
          color: Colors.grey[850],
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (widget.profilePictureUrl != null
                                        ? NetworkImage(
                                            widget.profilePictureUrl!,
                                          )
                                        : null)
                                    as ImageProvider?,
                          child:
                              (widget.profilePictureUrl == null &&
                                  _selectedImage == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _pseudoCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Pseudo",
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.person, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _saving ? null : _saveChanges,
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Enregistrer les modifications"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
