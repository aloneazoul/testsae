import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:spotshare/services/trip_service.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/story_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'package:spotshare/pages/Publication/post/gallery_picker_page.dart';
import 'package:spotshare/widgets/bottom_navigation.dart';
import 'package:spotshare/pages/Publication/trip/create_trip_page.dart';
import 'package:spotshare/pages/Publication/post/map_selector_page.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class PublishPage extends StatefulWidget {
  final int returnIndex;
  const PublishPage({super.key, this.returnIndex = 1});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  final List<XFile> _selectedImages = [];
  bool _loading = true;
  bool _isRecording = false;
  final TextEditingController _captionController = TextEditingController();
  double? selectedLat;
  double? selectedLon;
  String _postType = "POST";

  // Animation pour le bouton
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(_animationController);
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
          enableAudio: true,
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      _handleNewMedia(image);
    } catch (e) {
      debugPrint("Erreur prise de photo: $e");
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isRecordingVideo) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
      _animationController.forward(); // Animation
    } catch (e) {
      print("Erreur startRecording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return;
    try {
      final video = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      _animationController.reverse(); // Stop Animation
      _handleNewMedia(video);
    } catch (e) {
      print("Erreur stopRecording: $e");
    }
  }

  void _handleNewMedia(XFile file) {
    setState(() {
      if (_postType == "MEMORY" || _postType == "STORY") {
        _selectedImages.clear();
        _selectedImages.add(file);
      } else {
        _selectedImages.add(file);
      }
    });
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GalleryPickerPage(initialPostType: _postType)),
    );
    if (!mounted) return;
    if (result != null && result is Map) {
      final List<File> files = result['files'] ?? [];
      final String returnedType = result['postType'] ?? _postType;
      setState(() {
        _postType = returnedType; 
        if (_postType == "MEMORY" || _postType == "STORY") {
          _selectedImages.clear();
          if (files.isNotEmpty) {
            _selectedImages.add(XFile(files.first.path));
          }
        } else {
          _selectedImages.addAll(files.map((f) => XFile(f.path)));
        }
      });
    }
    await _initCamera();
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

  Future<void> _handlePublish() async {
    if (_postType == "STORY") {
      await _publishStory();
    } else {
      _showTripSelectionModal();
    }
  }

  Future<void> _publishStory() async {
     if (_selectedImages.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Publication de la story...")));
    final file = File(_selectedImages.first.path);
    final success = await _storyService.postStory(
      file: file,
      caption: _captionController.text,
      latitude: selectedLat,
      longitude: selectedLon,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => BottomNavigationBarExample(initialIndex: widget.returnIndex)), 
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Story publiée !"), backgroundColor: dGreen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la publication."), backgroundColor: Colors.red));
    }
  }

  void _showTripSelectionModal() {
     if (_selectedImages.isEmpty) return;
    if (selectedLat == null || selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner une localisation."), backgroundColor: Colors.red));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, color: Colors.grey[600]),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Publier ce ${_postType == 'POST' ? 'Post' : 'Memory'}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: dGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: dGreen)),
                    child: const Icon(Icons.add, color: dGreen),
                  ),
                  title: const Text("Créer un nouveau voyage", style: TextStyle(color: dGreen, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context); // Fermer le modal d'abord
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTripPage()));
                    if (result == true) { _showTripSelectionModal(); } // Rouvrir si succès
                  },
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _tripService.getMyTrips(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: dGreen));
                      final trips = snapshot.data ?? [];
                      if (trips.isEmpty) return const Center(child: Text("Aucun voyage existant.", style: TextStyle(color: Colors.grey)));
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          ImageProvider? bannerImage;
                          if (trip['banner'] != null) {
                            final String bannerPath = trip['banner'].toString();
                            final url = bannerPath.startsWith('http') ? bannerPath : "http://10.0.2.2:8000/$bannerPath";
                            bannerImage = NetworkImage(url);
                          }
                          return ListTile(
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                image: bannerImage != null ? DecorationImage(image: bannerImage, fit: BoxFit.cover) : null,
                              ),
                              child: bannerImage == null ? const Icon(Icons.map, color: Colors.white54) : null,
                            ),
                            title: Text(trip['trip_title'] ?? "Voyage", style: const TextStyle(color: Colors.white)),
                            subtitle: trip['start_date'] != null ? Text(trip['start_date'], style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
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
  }

  Future<void> _publishToTrip(int tripId) async {
    Navigator.pop(context); // Fermer le modal
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Envoi en cours...")));
    final files = _selectedImages.map((x) => File(x.path)).toList();
    final success = await _postService.createCarouselPost(
      tripId: tripId,
      imageFiles: files,
      caption: _captionController.text,
      latitude: selectedLat!,
      longitude: selectedLon!,
      postType: _postType,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BottomNavigationBarExample(initialIndex: 4)),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post publié !"), backgroundColor: dGreen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur publication."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
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

        // Sélecteur de type
        Positioned(
          bottom: 150, left: 0, right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildTypeSelector("POST"), _buildTypeSelector("MEMORY"), _buildTypeSelector("STORY")],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Contrôles bas
        Positioned(
          bottom: 40, left: 20, right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Galerie
              if (!_isRecording)
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                  onPressed: _pickFromGallery,
                )
              else 
                const SizedBox(width: 48),

              // BUG FIX #4 : Bouton d'enregistrement harmonisé et intuitif
              GestureDetector(
                onLongPress: _startRecording,
                onLongPressUp: _stopRecording,
                onTap: _takePicture,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isRecording ? 40 : 70,
                        height: _isRecording ? 40 : 70,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Switch caméra
              if (!_isRecording)
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                  onPressed: _toggleCamera,
                )
              else 
                const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(String type) {
    final isSelected = _postType == type;
    return GestureDetector(
      onTap: () {
        if (_postType != type) {
          setState(() => _postType = type);
          if (type == "STORY" || type == "MEMORY") {
             if (_selectedImages.length > 1) {
               final first = _selectedImages.first;
               _selectedImages.clear();
               _selectedImages.add(first);
             }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: isSelected ? BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(25)) : null,
        child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final file = _selectedImages[index];
              final extension = p.extension(file.path).toLowerCase();
              final isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(extension);
              return Stack(
                children: [
                  SizedBox.expand(child: isVideo ? _VideoPreviewItem(file: File(file.path)) : Image.file(File(file.path), fit: BoxFit.cover)),
                  if (_selectedImages.length > 1 || _selectedImages.isNotEmpty)
                    Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () { setState(() { _selectedImages.removeAt(index); if (_selectedImages.isEmpty) _retake(); }); })),
                  if (_selectedImages.length > 1)
                    Positioned(bottom: 16, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Text("${index + 1}/${_selectedImages.length}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))))),
                ],
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(20), color: Colors.black,
          child: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[850], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                icon: const Icon(Icons.location_on, size: 18),
                label: Text(selectedLat == null ? "Ajouter une localisation" : "Localisation ajoutée"),
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapSelectorPage()));
                  if (result != null && mounted) { setState(() { selectedLat = result["lat"]; selectedLon = result["lon"]; }); }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _captionController, 
                style: const TextStyle(color: Colors.white), 
                decoration: InputDecoration(
                  hintText: "Écrivez une légende...", 
                  hintStyle: TextStyle(color: Colors.grey[600]), 
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                )
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: _retake, child: const Text("Annuler", style: TextStyle(color: Colors.white))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: dGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: _handlePublish,
                    child: Text(_postType == "STORY" ? "Publier Story" : "Publier", style: const TextStyle(fontWeight: FontWeight.bold)),
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
    _animationController.dispose();
    super.dispose();
  }
}

class _VideoPreviewItem extends StatefulWidget {
  final File file;
  const _VideoPreviewItem({required this.file});
  @override
  State<_VideoPreviewItem> createState() => _VideoPreviewItemState();
}

class _VideoPreviewItemState extends State<_VideoPreviewItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)..initialize().then((_) { setState(() => _initialized = true); _controller.setLooping(true); _controller.play(); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () { if (_controller.value.isPlaying) { _controller.pause(); } else { _controller.play(); } },
      child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
    );
  }
}