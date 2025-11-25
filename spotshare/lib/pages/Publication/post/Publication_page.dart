import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _loading = true;
  XFile? _capturedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;

    final image = await _cameraController!.takePicture();

    setState(() {
      _capturedImage = image;
    });
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _capturedImage = image;
      });
    }
  }

  void _publish() {
    if (_capturedImage == null) return;

    print("🔵 Publication envoyée : ${_capturedImage!.path}");

    // Ici : envoie la photo + description à ton API

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Photo publiée !")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle publication")),
      body: Column(
        children: [
          Expanded(
            child: _capturedImage == null
                ? CameraPreview(_cameraController!)
                : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
          ),
        ],
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton pour prendre une photo
          FloatingActionButton(
            heroTag: "cameraBtn",
            onPressed: _takePicture,
            child: const Icon(Icons.camera_alt),
          ),

          // Bouton pour choisir dans la galerie
          FloatingActionButton(
            heroTag: "galleryBtn",
            onPressed: _pickFromGallery,
            child: const Icon(Icons.photo_library),
          ),

          // Bouton publish
          if (_capturedImage != null)
            FloatingActionButton(
              heroTag: "sendBtn",
              backgroundColor: Colors.green,
              onPressed: _publish,
              child: const Icon(Icons.send),
            ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
