import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:spotshare/utils/constants.dart';

class GalleryPickerPage extends StatefulWidget {
  final String initialPostType;

  const GalleryPickerPage({super.key, this.initialPostType = "POST"});

  @override
  State<GalleryPickerPage> createState() => _GalleryPickerPageState();
}

class _GalleryPickerPageState extends State<GalleryPickerPage>
    with WidgetsBindingObserver {
  List<AssetEntity> _mediaList = [];
  List<AssetEntity> _selectedList = [];
  List<AssetPathEntity> _albums = []; // Liste des albums
  AssetPathEntity? _currentAlbum; // Album sélectionné

  bool _isMultipleMode = false;
  bool _loading = true;
  bool _permissionDenied = false;
  final PageController _pageController = PageController();
  late String _selectedPostType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedPostType = widget.initialPostType;
    if (_selectedPostType == "MEMORY" || _selectedPostType == "STORY") {
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
    setState(() => _loading = true);

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth || ps.isLimited) {
      try {
        // BUG FIX #3 : RequestType.all pour avoir Photos ET Vidéos
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.all,
          hasAll: true, // Inclure l'album "Récents"
        );

        if (albums.isEmpty) {
          setState(() => _loading = false);
          return;
        }

        setState(() {
          _albums = albums;
          _currentAlbum =
              albums.first; // Sélectionner le premier (Récents) par défaut
        });

        await _loadAssetsFromCurrentAlbum();
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

  Future<void> _loadAssetsFromCurrentAlbum() async {
    if (_currentAlbum == null) return;

    try {
      final List<AssetEntity> media = await _currentAlbum!.getAssetListPaged(
        page: 0,
        size: 500,
      );

      // Debug: Check all asset types
      int imageCount = 0;
      int videoCount = 0;
      int otherCount = 0;

      for (var asset in media) {
        debugPrint("Asset: type=${asset.type}, duration=${asset.duration}");
        if (asset.type == AssetType.image) {
          imageCount++;
        } else if (asset.type == AssetType.video) {
          videoCount++;
        } else {
          otherCount++;
        }
      }

      debugPrint(
        "Gallery: Loaded ${media.length} items - "
        "$imageCount images, $videoCount videos, $otherCount other",
      );

      final List<AssetEntity> sorted = media.toList();
      sorted.sort(
        (a, b) => (b.createDateTime?.millisecondsSinceEpoch ?? 0).compareTo(
          a.createDateTime?.millisecondsSinceEpoch ?? 0,
        ),
      );

      setState(() {
        _mediaList = sorted;
      });
    } catch (e, stackTrace) {
      debugPrint("Failed to load assets: $e");
      debugPrint("$stackTrace");
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
    if (_selectedPostType == "MEMORY" || _selectedPostType == "STORY") return;
    setState(() {
      _isMultipleMode = !_isMultipleMode;
      if (!_isMultipleMode && _selectedList.isNotEmpty) {
        _selectedList = [_selectedList.first];
      }
    });
  }

  void _removeFromSelection(int index) {
    setState(() {
      if (_selectedList.length <= 1) return;
      _selectedList.removeAt(index);
      int newIndex = index >= _selectedList.length
          ? _selectedList.length - 1
          : index;
      if (_pageController.hasClients) _pageController.jumpToPage(newIndex);
    });
  }

  void _changePostType(String newType) {
    setState(() {
      _selectedPostType = newType;
      if (newType == "MEMORY" || newType == "STORY") {
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
      "postType": _selectedPostType,
    });
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
        // BUG FIX #3 : Dropdown pour choisir l'album
        title: _loading
            ? const Text("Galerie")
            : DropdownButton<AssetPathEntity>(
                value: _currentAlbum,
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                onChanged: (AssetPathEntity? newAlbum) {
                  if (newAlbum != null && newAlbum != _currentAlbum) {
                    setState(() {
                      _currentAlbum = newAlbum;
                      _loading = true;
                    });
                    _loadAssetsFromCurrentAlbum();
                  }
                },
                items: _albums.map((album) {
                  return DropdownMenuItem(
                    value: album,
                    child: Text(
                      album.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: _selectedList.isNotEmpty
                ? _confirmSelectionAndReturn
                : null,
            child: Text(
              "Suivant",
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
          Column(
            children: [
              // Aperçu
              SizedBox(
                height: 350,
                child: _selectedList.isEmpty
                    ? Container(color: Colors.grey[900])
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _selectedList.length,
                            itemBuilder: (context, index) {
                              final asset = _selectedList[index];
                              return Image(
                                image: AssetEntityImageProvider(
                                  asset,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize(
                                    1080,
                                    1080,
                                  ),
                                ),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          if (_selectedList.length > 1)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => _removeFromSelection(
                                  _pageController.page?.round() ?? 0,
                                ),
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
                                    "${_pageController.hasClients ? (_pageController.page?.round() ?? 0) + 1 : 1}/${_selectedList.length}",
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

              // Barre d'outils
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .end, // Juste le bouton multiple à droite
                  children: [
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

              // Grille
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: dGreen),
                      )
                    : _permissionDenied
                    ? const Center(
                        child: Text(
                          "Accès refusé",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 2),
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
                                    thumbnailSize: const ThumbnailSize.square(
                                      200,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                if (asset.type == AssetType.video)
                                  const Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                if (asset.duration > 0)
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Text(
                                      "${(asset.duration / 60).floor()}:${(asset.duration % 60).toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        shadows: [Shadow(blurRadius: 2)],
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  Container(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                if (isSelected &&
                                    _isMultipleMode &&
                                    _selectedPostType == "POST")
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: dGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
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

          // Sélecteur de type
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypeSelector("POST"),
                        _buildTypeSelector("MEMORY"),
                        _buildTypeSelector("STORY"),
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
                color: Colors.black.withOpacity(0.7),
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
