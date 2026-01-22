import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:spotshare/utils/constants.dart';

class GalleryPickerPage extends StatefulWidget {
  const GalleryPickerPage({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        // Récupérer tous les albums, pas seulement "All"
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: false, // <-- récupérer tous les albums
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
      if (_isMultipleMode) {
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
    setState(() {
      _isMultipleMode = !_isMultipleMode;
      if (!_isMultipleMode && _selectedList.isNotEmpty) {
        _selectedList = [_selectedList.first];
      }
    });
  }

  void _removeFromSelection(int index) {
    setState(() {
      _selectedList.removeAt(index);
      if (_selectedList.isEmpty) return;

      int newIndex = index;
      if (_pageController.hasClients) {
        if (newIndex >= _selectedList.length) {
          newIndex = _selectedList.length - 1;
        }
        _pageController.jumpToPage(newIndex);
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
    Navigator.pop(context, filesToReturn);
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
      body: Column(
        children: [
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
                          return Image(
                            image: AssetEntityImageProvider(
                              _selectedList[index],
                              isOriginal: false,
                            ),
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            if (_selectedList.isEmpty) return;
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: dGreen))
                : _permissionDenied
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Accès aux photos refusé.",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openAppSettings,
                          child: const Text("Ouvrir les paramètres"),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchAssets,
                          child: const Text(
                            "Réessayer",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
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
                                thumbnailSize: const ThumbnailSize.square(200),
                              ),
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              Container(color: Colors.white.withOpacity(0.3)),
                            if (isSelected && _isMultipleMode)
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
    );
  }
}
