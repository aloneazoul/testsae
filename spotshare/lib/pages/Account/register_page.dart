import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spotshare/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _pseudoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  DateTime? _birthDate;

  File? _selectedImage;
  bool _obscure = true;
  bool _loading = false;

  // Nouveaux champs
  String? _selectedGender;
  String _isPrivateFlag = "N";

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pseudoCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return "Veuillez saisir un email";
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v.trim())) return "Email invalide";
    return null;
  }

  String? _validatePseudo(String? v) {
    if (v == null || v.isEmpty) return "Veuillez saisir un pseudo";
    if (v.length < 3) return "3 caractères minimum";
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return "Veuillez saisir un mot de passe";
    if (v.length < 6) return "6 caractères minimum";
    return null;
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _birthDate = date;
        _birthDateCtrl.text =
            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      });
    }
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date")),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un genre")),
      );
      return;
    }

    setState(() => _loading = true);

    // Convertir date en format type API (YYYY-MM-DD)
    final birthDateFormatted =
        "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}";

    try {
      final success = await CreateUser(
        _emailCtrl.text.trim(),
        _pseudoCtrl.text.trim(),
        _passwordCtrl.text,
        _selectedImage,
        _selectedGender!,
        _bioCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        birthDateFormatted,
        _isPrivateFlag,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Compte créé avec succès !"
                : "Échec de la création du compte",
          ),
        ),
      );

      if (success) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Card(
          color: Colors.grey[850],
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Créer un compte",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[700],
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                            child: _selectedImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // EMAIL
                    TextFormField(
                      controller: _emailCtrl,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PSEUDO
                    TextFormField(
                      controller: _pseudoCtrl,
                      validator: _validatePseudo,
                      decoration: const InputDecoration(
                        labelText: "Pseudo",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PASSWORD
                    TextFormField(
                      controller: _passwordCtrl,
                      validator: _validatePassword,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PHONE
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: "Numéro de téléphone",
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    // BIO
                    TextFormField(
                      controller: _bioCtrl,
                      decoration: const InputDecoration(
                        labelText: "Bio",
                        prefixIcon: Icon(Icons.text_snippet),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 12),

                    // GENRE
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: "Genre",
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Homme", child: Text("Homme")),
                        DropdownMenuItem(value: "Femme", child: Text("Femme")),
                        DropdownMenuItem(value: "Autre", child: Text("Autre")),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),

                    const SizedBox(height: 12),

                    // DATE DE NAISSANCE
                    TextFormField(
                      controller: _birthDateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Date de naissance",
                        prefixIcon: Icon(Icons.cake),
                      ),
                      onTap: _pickBirthDate,
                    ),

                    const SizedBox(height: 12),

                    // PRIVATE FLAG
                    SwitchListTile(
                      title: const Text(
                        "Compte privé",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isPrivateFlag == "Y",
                      onChanged: (v) =>
                          setState(() => _isPrivateFlag = v ? "Y" : "N"),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Créer mon compte"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
