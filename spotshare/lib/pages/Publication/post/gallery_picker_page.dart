import 'dart:io';
import 'dart:ui'; // Nécessaire pour BackdropFilter
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:spotshare/utils/constants.dart';

class GalleryPickerPage extends StatefulWidget {
  final String initialPostType; // "POST" ou "MEMORY"

  const GalleryPickerPage({super.key, this.initialPostType = "POST"});

  @override
  State<GalleryPickerPage> createState() => _GalleryPickerPageState();
}

class _GalleryPickerPageState extends State<GalleryPickerPage>
    with WidgetsBindingObserver {
  List<AssetEntity> _mediaList = [];
  List<AssetEntity> _selectedList = [];
  bool _isMultipleMode = false;
  bool _loading = true;
  bool _permissionDenied = false;
  PageController _pageController = PageController();

  late String _selectedPostType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedPostType = widget.initialPostType;
    if (_selectedPostType == "MEMORY") {
      _isMultipleMode = false;
    }
    _fetchAssets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAssets();
    }
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
      _mediaList = [];
      _selectedList = [];
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth || ps.isLimited) {
      try {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.common,
          onlyAll: false,
        );

        List<AssetEntity> allMedia = [];

        for (var album in albums) {
          List<AssetEntity> media = await album.getAssetListPaged(
            page: 0,
            size: 200,
          );
          allMedia.addAll(media);
        }

        setState(() {
          _mediaList = allMedia;
          if (_mediaList.isNotEmpty) _selectedList = [_mediaList[0]];
          _loading = false;
        });
      } catch (e) {
        debugPrint("Erreur fetch assets: $e");
        setState(() => _loading = false);
      }
    } else {
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
    }
  }

  void _handleAssetTap(AssetEntity asset) {
    setState(() {
      if (_isMultipleMode && _selectedPostType == "POST") {
        if (_selectedList.any((e) => e.id == asset.id)) {
          _selectedList.removeWhere((e) => e.id == asset.id);
        } else if (_selectedList.length < 10) {
          _selectedList.add(asset);
        }
      } else {
        _selectedList = [asset];
      }
    });
  }

  void _toggleMultipleMode() {
    if (_selectedPostType == "MEMORY") return;

    setState(() {
      _isMultipleMode = !_isMultipleMode;
      if (!_isMultipleMode && _selectedList.isNotEmpty) {
        _selectedList = [_selectedList.first];
      }
    });
  }

  void _removeFromSelection(int index) {
    setState(() {
      // CORRECTION : On empêche de supprimer s'il ne reste qu'une seule photo
      if (_selectedList.length <= 1) return;

      _selectedList.removeAt(index);
      
      int newIndex = index;
      if (_pageController.hasClients) {
        if (newIndex >= _selectedList.length) {
          newIndex = _selectedList.length - 1;
        }
        _pageController.jumpToPage(newIndex);
      }
    });
  }

  void _changePostType(String newType) {
    setState(() {
      _selectedPostType = newType;
      if (newType == "MEMORY") {
        _isMultipleMode = false;
        if (_selectedList.length > 1) {
          _selectedList = [_selectedList.first];
        }
      }
    });
  }

  Future<void> _confirmSelectionAndReturn() async {
    if (_selectedList.isEmpty) return;
    List<File> filesToReturn = [];
    for (var asset in _selectedList) {
      final file = await asset.file;
      if (file != null) filesToReturn.add(file);
    }
    if (!mounted) return;
    
    Navigator.pop(context, {
      "files": filesToReturn,
      "postType": _selectedPostType
    });
  }

  void _openAppSettings() {
    PhotoManager.openSetting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nouvelle publication",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _selectedList.isNotEmpty
                ? _confirmSelectionAndReturn
                : null,
            child: Text(
              "Valider",
              style: TextStyle(
                color: _selectedList.isNotEmpty ? dGreen : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // CONTENU PRINCIPAL (Preview + Grid)
          Column(
            children: [
              // PREVIEW AREA
              SizedBox(
                height: 300,
                child: _selectedList.isEmpty
                    ? Container(color: Colors.grey[900])
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _selectedList.length,
                            onPageChanged: (index) {
                              setState(() {});
                            },
                            itemBuilder: (context, index) {
                              final asset = _selectedList[index];
                              return Image(
                                image: AssetEntityImageProvider(
                                  asset,
                                  isOriginal: false,
                                  // CORRECTION FLOU : On demande une vignette HD pour la preview
                                  thumbnailSize: const ThumbnailSize(1080, 1080),
                                ),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          
                          // CROIX DE SUPPRESSION (Seulement si > 1 image)
                          if (_selectedList.length > 1)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  int currentIndex = _pageController.hasClients
                                      ? _pageController.page!.round()
                                      : 0;
                                  _removeFromSelection(currentIndex);
                                },
                              ),
                            ),

                          if (_selectedList.isNotEmpty)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${_pageController.hasClients ? _pageController.page!.round() + 1 : 1}/${_selectedList.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              
              // TOOLBAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Récent",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_selectedPostType == "POST")
                      GestureDetector(
                        onTap: _toggleMultipleMode,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isMultipleMode ? dGreen : Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // GRID AREA
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: dGreen))
                    : _permissionDenied
                    ? const Center(child: Text("Accès refusé", style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100), // Espace pour le sélecteur flottant
                        itemCount: _mediaList.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                        itemBuilder: (context, index) {
                          final asset = _mediaList[index];
                          int selectionIndex = _selectedList.indexWhere(
                            (e) => e.id == asset.id,
                          );
                          bool isSelected = selectionIndex != -1;

                          return GestureDetector(
                            onTap: () => _handleAssetTap(asset),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image(
                                  image: AssetEntityImageProvider(
                                    asset,
                                    isOriginal: false,
                                    // CORRECTION FLOU : Vignette plus grande pour écrans modernes
                                    thumbnailSize: const ThumbnailSize.square(500), 
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                if (asset.type == AssetType.video)
                                  const Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Icon(Icons.videocam, color: Colors.white, size: 16),
                                  ),

                                if (isSelected)
                                  Container(color: Colors.white.withOpacity(0.3)),
                                
                                if (isSelected && _isMultipleMode && _selectedPostType == "POST")
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: dGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${selectionIndex + 1}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // SÉLECTEUR FLOTTANT (Style Glassmorphism)
          Positioned(
            bottom: 40, // Remonté pour éviter la barre d'accueil
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Effet de flou
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4), // Fond gris translucide
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypeSelector("POST"),
                        _buildTypeSelector("MEMORY"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(String type) {
    final isSelected = _selectedPostType == type;
    return GestureDetector(
      onTap: () => _changePostType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: isSelected 
          ? BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Fond actif plus sombre
              borderRadius: BorderRadius.circular(25),
            )
          : null,
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}