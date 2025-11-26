import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spotshare/services/post_service.dart'; // Assurez-vous d'avoir créé ce fichier comme vu précédemment
import 'package:spotshare/utils/constants.dart'; // Pour les couleurs (dGreen)

class PublishPage extends StatefulWidget {
  final int? tripId; // On accepte un ID de voyage optionnel

  const PublishPage({super.key, this.tripId});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _loading = true;
  bool _isPublishing = false;
  
  XFile? _capturedImage;
  final TextEditingController _descriptionController = TextEditingController();
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
      }
    } catch (e) {
      print("Erreur caméra: $e");
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      print("Erreur photo: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      print("Erreur galerie: $e");
    }
  }

  Future<void> _publish() async {
    if (_capturedImage == null) return;

    setState(() => _isPublishing = true);

    // Appel au service avec l'ID du voyage (si présent)
    final success = await _postService.createPost(
      description: _descriptionController.text,
      imageFile: File(_capturedImage!.path),
      tripId: widget.tripId, // IMPORTANT : On lie le post au voyage
    );

    if (mounted) {
      setState(() => _isPublishing = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Souvenir publié ! 🚀"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // On renvoie 'true' pour dire que ça a marché
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- MODE 1 : CAMERA (Si pas d'image capturée) ---
    if (_capturedImage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Prendre une photo")),
        body: _cameraController != null && _cameraController!.value.isInitialized
            ? CameraPreview(_cameraController!)
            : const Center(child: Text("Caméra indisponible")),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: "galleryBtn",
              onPressed: _pickFromGallery,
              child: const Icon(Icons.photo_library),
            ),
            FloatingActionButton(
              heroTag: "cameraBtn",
              backgroundColor: dGreen,
              onPressed: _takePicture,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    }

    // --- MODE 2 : ÉDITION (Si image capturée) ---
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouveau Souvenir"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _capturedImage = null), // Annuler la photo
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Racontez ce souvenir...",
                  border: OutlineInputBorder(),
                  hintText: "Ex: Une vue magnifique sur les montagnes...",
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isPublishing ? null : _publish,
                  icon: _isPublishing 
                      ? const SizedBox.shrink() 
                      : const Icon(Icons.send),
                  label: _isPublishing
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("PUBLIER LE SOUVENIR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}