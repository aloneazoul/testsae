import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/services/trip_service.dart';
import 'dart:io'; // NOUVEL IMPORT pour File
import 'package:image_picker/image_picker.dart'; // NOUVEL IMPORT

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TripService _tripService = TripService();

  // Contrôleurs
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Variables d'état
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublic = true; 
  bool _isLoading = false;
  File? _bannerImage; // NOUVELLE VARIABLE pour l'image

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // -------------------------------------------
  // SÉLECTION DE L'IMAGE
  // -------------------------------------------
  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  // -------------------------------------------
  // SÉLECTION DE DATE (AMÉLIORÉE)
  // -------------------------------------------
  Future<void> _pickDate({required bool isStart}) async {
    // ... (Logique de _pickDate inchangée, elle fonctionne) ...
    DateTime firstAllowedDate = DateTime(2000);
    DateTime initialDisplayDate = DateTime.now();

    if (!isStart) {
      if (_startDate != null) {
        firstAllowedDate = _startDate!;
        initialDisplayDate = _startDate!;
      }
    } else {
      initialDisplayDate = _startDate ?? DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDisplayDate,
      firstDate: firstAllowedDate, 
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: dGreen,
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Date de fin réinitialisée car antérieure au début.")),
            );
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // -------------------------------------------
  // ENVOI DU FORMULAIRE (MISE À JOUR API)
  // -------------------------------------------
  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("La date de fin ne peut pas être avant la date de début !"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // 1. Préparation des données texte pour l'API
    final Map<String, dynamic> tripData = {
      "trip_title": _titleController.text.trim(),
      "trip_description": _descController.text.trim().isEmpty 
          ? null 
          : _descController.text.trim(),
      "start_date": _startDate?.toIso8601String().split('T')[0],
      "end_date": _endDate?.toIso8601String().split('T')[0],
      "is_public_flag": _isPublic ? "Y" : "N",
    };

    // 2. Appel API avec le fichier _bannerImage
    final bool success = await _tripService.createTrip(tripData, _bannerImage);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voyage créé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la création du voyage."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // -------------------------------------------
  // UI
  // -------------------------------------------
  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime? d) =>
        d == null ? "Sélectionner" : "${d.day}/${d.month}/${d.year}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Créer un voyage", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOUVEAU CHAMP : BANNER IMAGE
              _buildLabel("Image de Bannière (Optionnel)"),
              GestureDetector(
                onTap: _pickBannerImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: _bannerImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _bannerImage!,
                            fit: BoxFit.cover,
                            height: 150,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: dGreen),
                              const SizedBox(height: 8),
                              const Text(
                                "Ajouter une image de couverture",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // TITRE (existants)
              _buildLabel("Titre du voyage"),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Ex: Roadtrip en Californie"),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Le titre est obligatoire" : null,
              ),
              const SizedBox(height: 20),
              // ... reste du formulaire (Description, Dates, Switch) ...
              
              // DESCRIPTION
              _buildLabel("Description"),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDecoration("Racontez-nous votre projet..."),
              ),
              const SizedBox(height: 20),

              // DATES
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Date de début"),
                        _buildDateSelector(
                          label: formatDate(_startDate),
                          icon: Icons.calendar_today,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Date de fin"),
                        _buildDateSelector(
                          label: formatDate(_endDate),
                          icon: Icons.event,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SWITCH PUBLIC/PRIVÉ
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SwitchListTile(
                  activeColor: dGreen,
                  title: const Text("Voyage Public", style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _isPublic ? "Tout le monde peut voir ce voyage" : "Visible uniquement par vous",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                ),
              ),

              const SizedBox(height: 40),

              // BOUTON VALIDER
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _submitTrip,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Créer le voyage",
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPERS (non modifiés)
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildDateSelector({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: dGreen, width: 1),
      ),
    );
  }
}