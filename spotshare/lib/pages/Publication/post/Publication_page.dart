import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Publication/post/gallery_picker_page.dart';
import 'package:spotshare/widgets/bottom_navigation.dart';
import 'package:spotshare/pages/Publication/trip/create_trip_page.dart';
import 'package:spotshare/pages/Publication/post/map_selector_page.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final TripService _tripService = TripService();
  final PostService _postService = PostService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  final List<XFile> _selectedImages = [];
  bool _loading = true;
  final TextEditingController _captionController = TextEditingController();

  double? selectedLat;
  double? selectedLon;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _loading = true);
    try {
      if (_cameras == null) {
        _cameras = await availableCameras();
      }

      if (_cameras != null && _cameras!.isNotEmpty) {
        if (_selectedCameraIndex >= _cameras!.length) {
          _selectedCameraIndex = 0;
        }

        if (_cameraController != null) {
          await _cameraController!.dispose();
        }

        _cameraController = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint("Erreur caméra (init): $e");
      _cameraController = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });

    await _initCamera();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _selectedImages.clear();
        _selectedImages.add(image);
      });
    } catch (e) {
      debugPrint("Erreur prise de photo: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      debugPrint("Erreur lors du dispose caméra: $e");
    }

    final result = await Navigator.push<List<File>?>(
      context,
      MaterialPageRoute(builder: (context) => const GalleryPickerPage()),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(result.map((f) => XFile(f.path)));
      });
    } else {
      await _initCamera();
    }
  }

  void _retake() {
    setState(() {
      _selectedImages.clear();
      _captionController.clear();
      selectedLat = null;
      selectedLon = null;
    });
    _initCamera();
  }

  void _showTripSelectionModal() {
    if (_selectedImages.isEmpty) return;

    if (selectedLat == null || selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner une localisation."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, color: Colors.grey[600]),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Dans quel voyage ajouter ce post ?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: dGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: dGreen),
                        ),
                        child: const Icon(Icons.add, color: dGreen),
                      ),
                      title: const Text(
                        "Créer un nouveau voyage",
                        style: TextStyle(
                          color: dGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateTripPage(),
                          ),
                        );
                        if (result == true) {
                          setModalState(() {});
                        }
                      },
                    ),
                    const Divider(color: Colors.grey),

                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _tripService.getMyTrips(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: dGreen),
                            );
                          }

                          final trips = snapshot.data ?? [];

                          if (trips.isEmpty) {
                            return const Center(
                              child: Text(
                                "Aucun voyage existant.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: trips.length,
                            itemBuilder: (context, index) {
                              final trip = trips[index];

                              ImageProvider? bannerImage;
                              if (trip['banner'] != null) {
                                final String bannerPath = trip['banner']
                                    .toString();
                                final url = bannerPath.startsWith('http')
                                    ? bannerPath
                                    : "http://10.0.2.2:8000/$bannerPath";
                                bannerImage = NetworkImage(url);
                              }

                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                    image: bannerImage != null
                                        ? DecorationImage(
                                            image: bannerImage,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: bannerImage == null
                                      ? const Icon(
                                          Icons.map,
                                          color: Colors.white54,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  trip['trip_title'] ?? "Voyage",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: trip['start_date'] != null
                                    ? Text(
                                        trip['start_date'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                onTap: () => _publishToTrip(trip['trip_id']),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _publishToTrip(int tripId) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Envoi en cours...")));

    final files = _selectedImages.map((x) => File(x.path)).toList();

    final success = await _postService.createCarouselPost(
      tripId: tripId,
      imageFiles: files,
      caption: _captionController.text,
      latitude: selectedLat!,
      longitude: selectedLon!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              const BottomNavigationBarExample(initialIndex: 4),
        ),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post publié !"), backgroundColor: dGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur publication."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _selectedImages.isEmpty ? _buildCameraView() : _buildPreviewView(),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        if (_cameraController != null && _cameraController!.value.isInitialized)
          SizedBox.expand(child: CameraPreview(_cameraController!))
        else
          Container(color: Colors.black),

        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: "gallery",
                backgroundColor: Colors.grey[800],
                onPressed: _pickFromGallery,
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: "snap",
                backgroundColor: Colors.white,
                child: const Icon(Icons.circle, size: 50, color: Colors.black),
                onPressed: _takePicture,
              ),
              FloatingActionButton(
                heroTag: "switch",
                backgroundColor: Colors.grey[800],
                onPressed: _toggleCamera,
                child: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    if (_selectedImages.isEmpty) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final file = _selectedImages[index];
              return Stack(
                children: [
                  SizedBox.expand(
                    child: Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "${index + 1}/${_selectedImages.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black38,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.black,
          child: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.location_on),
                label: Text(
                  selectedLat == null
                      ? "Ajouter une localisation"
                      : "Localisation : ${selectedLat!.toStringAsFixed(4)}, ${selectedLon!.toStringAsFixed(4)}",
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapSelectorPage(),
                    ),
                  );

                  if (result != null && mounted) {
                    setState(() {
                      selectedLat = result["lat"];
                      selectedLon = result["lon"];
                    });
                  }
                },
              ),

              TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Légende...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _retake,
                    child: const Text(
                      "Annuler",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dGreen,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _showTripSelectionModal,
                    child: const Text("Suivant"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captionController.dispose();
    super.dispose();
  }
}
