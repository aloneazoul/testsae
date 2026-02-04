import 'dart:io';
import 'dart:ui'; // Nécessaire pour BackdropFilter
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:spotshare/utils/constants.dart';

class GalleryPickerPage extends StatefulWidget {
  final String initialPostType; // "POST", "MEMORY", ou "STORY"

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
  final PageController _pageController = PageController();

  late String _selectedPostType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedPostType = widget.initialPostType;
    
    // Si c'est MEMORY ou STORY, on désactive le mode multiple par défaut
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
          onlyAll: true, // On prend "Recent" par défaut
        );

        // Si aucun album, on arrête
        if (albums.isEmpty) {
           setState(() => _loading = false);
           return;
        }

        // On charge les médias du premier album (Récent)
        List<AssetEntity> media = await albums[0].getAssetListPaged(
          page: 0,
          size: 200, // On charge les 200 premiers pour l'instant
        );

        setState(() {
          _mediaList = media;
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
      // Seul le mode POST autorise la sélection multiple
      if (_isMultipleMode && _selectedPostType == "POST") {
        if (_selectedList.any((e) => e.id == asset.id)) {
          _selectedList.removeWhere((e) => e.id == asset.id);
        } else if (_selectedList.length < 10) {
          _selectedList.add(asset);
        }
      } else {
        // Pour MEMORY et STORY, on remplace la sélection
        _selectedList = [asset];
      }
    });
  }

  void _toggleMultipleMode() {
    // Interdit pour MEMORY et STORY
    if (_selectedPostType == "MEMORY" || _selectedPostType == "STORY") return;

    setState(() {
      _isMultipleMode = !_isMultipleMode;
      // Si on désactive le mode multiple, on ne garde que la première image sélectionnée
      if (!_isMultipleMode && _selectedList.isNotEmpty) {
        _selectedList = [_selectedList.first];
      }
    });
  }

  void _removeFromSelection(int index) {
    setState(() {
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
      // Si on passe à MEMORY ou STORY, on force le mode unique
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
    
    // Conversion des assets en fichiers
    List<File> filesToReturn = [];
    for (var asset in _selectedList) {
      final file = await asset.file;
      if (file != null) filesToReturn.add(file);
    }
    
    if (!mounted) return;
    
    // On renvoie les fichiers ET le type choisi (pour mettre à jour la page précédente)
    Navigator.pop(context, {
      "files": filesToReturn,
      "postType": _selectedPostType
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
          // 1. CONTENU PRINCIPAL
          Column(
            children: [
              // ZONE DE PREVISUALISATION (HAUT)
              SizedBox(
                height: 350, // Un peu plus grand pour bien voir
                child: _selectedList.isEmpty
                    ? Container(color: Colors.grey[900])
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _selectedList.length,
                            onPageChanged: (index) {
                              setState(() {}); // Rafraîchir pour le compteur
                            },
                            itemBuilder: (context, index) {
                              final asset = _selectedList[index];
                              return Image(
                                image: AssetEntityImageProvider(
                                  asset,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize(1080, 1080), // HD
                                ),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          
                          // Croix pour retirer une image (si multiple)
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

                          // Compteur (1/3)
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
              
              // BARRE D'OUTILS (Récent + Bouton Multiple)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Récent",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Le bouton "Multiple" ne s'affiche que pour POST
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

              // GRILLE DES PHOTOS
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: dGreen))
                    : _permissionDenied
                    ? const Center(child: Text("Accès refusé", style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 2), 
                        itemCount: _mediaList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    thumbnailSize: const ThumbnailSize.square(400),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                
                                if (asset.type == AssetType.video)
                                  const Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: Icon(Icons.videocam, color: Colors.white, size: 16),
                                  ),

                                if (isSelected)
                                  Container(color: Colors.white.withOpacity(0.4)),
                                
                                // Numéro de sélection (si multiple)
                                if (isSelected && _isMultipleMode && _selectedPostType == "POST")
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: dGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
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

          // 2. SÉLECTEUR FLOTTANT (EN BAS)
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                        _buildTypeSelector("STORY"), // AJOUT DE L'ONGLET STORY ICI
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