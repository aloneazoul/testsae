import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;

class Landmark {
  final String name;
  final String image;
  final String owner;
  final Point coords;

  Landmark({
    required this.name,
    required this.image,
    required this.owner,
    required this.coords,
  });
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _DarkMapboxWidgetState();
}

class _DarkMapboxWidgetState extends State<MapPage> {
  late MapboxMap _mapboxMap;
  bool _mapReady = false;

  final List<Landmark> _landmarks = [
    Landmark(
      name: "Tour Eiffel",
      image: "assets/images/tour_eiffel.jpg",
      owner: "Alexis",
      coords: Point(coordinates: Position(2.2945, 48.8584)),
    ),
    Landmark(
      name: "Uluru (Ayers Rock)",
      image: "assets/images/uluru.jpg",
      owner: "Alone",
      coords: Point(coordinates: Position(131.0369, -25.3444)),
    ),
    Landmark(
      name: "Statue de la Liberté",
      image: "assets/images/liberty.jpeg",
      owner: "Clem",
      coords: Point(coordinates: Position(-74.0445, 40.6892)),
    ),
    Landmark(
      name: "Machu Picchu",
      image: "assets/images/machu-picchu.jpeg",
      owner: "Antoine",
      coords: Point(coordinates: Position(-72.5450, -13.1631)),
    ),
    Landmark(
      name: "Grande Muraille de Chine",
      image: "assets/images/muraille_chine.webp",
      owner: "Alone",
      coords: Point(coordinates: Position(116.5704, 40.4319)),
    ),
  ];

  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    const ACCESS_TOKEN =
        'pk.eyJ1IjoiYWxleGlzZHoiLCJhIjoiY21nNmtrcWc4MGUxaTJoczI1cm5jbGZwdCJ9.x10xKnS4jeJGgs3EuWbdUg';
    MapboxOptions.setAccessToken(ACCESS_TOKEN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            styleUri: "mapbox://styles/alexisdz/cmgi1acn6001701s3b4y93lse",
            cameraOptions: CameraOptions(
              center: _landmarks.first.coords,
              zoom: 1.5,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: (CameraChangedEventData data) async {
              if (_mapReady) await _updateAllMarkerPositions();
            },
          ),
          ..._positions.entries.map((entry) {
            final lm = _landmarks.firstWhere((l) => l.name == entry.key);
            final pos = entry.value;

            return Positioned(
              left: pos.dx - 60,
              top: pos.dy - 150,
              child: _MapMarkerWidget(
                landmark: lm,
                onTap: (landmark) => _showLandmarkDetails(landmark),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    setState(() => _mapReady = true);
    await _updateAllMarkerPositions();
    await _mapboxMap.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );
  }

  bool _isVisibleOnGlobe(Position cam, Position target) {
    final lat1 = cam.lat * pi / 180;
    final lon1 = cam.lng * pi / 180;
    final lat2 = target.lat * pi / 180;
    final lon2 = target.lng * pi / 180;
    final v1 = [cos(lat1) * cos(lon1), cos(lat1) * sin(lon1), sin(lat1)];
    final v2 = [cos(lat2) * cos(lon2), cos(lat2) * sin(lon2), sin(lat2)];
    final dot = v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
    return dot > 0;
  }

  Future<void> _updateAllMarkerPositions() async {
    final camera = await _mapboxMap.getCameraState();
    final camPos = camera.center!.coordinates;
    final newPositions = <String, Offset>{};

    for (final lm in _landmarks) {
      try {
        if (!_isVisibleOnGlobe(camPos, lm.coords.coordinates)) continue;
        final screenCoords = await _mapboxMap.pixelForCoordinate(lm.coords);

        if (screenCoords.x.isNaN ||
            screenCoords.y.isNaN ||
            screenCoords.x < 0 ||
            screenCoords.y < 0 ||
            screenCoords.x > MediaQuery.of(context).size.width ||
            screenCoords.y > MediaQuery.of(context).size.height)
          continue;

        newPositions[lm.name] = Offset(screenCoords.x, screenCoords.y);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _positions
        ..clear()
        ..addAll(newPositions);
    });
  }

  void _showLandmarkDetails(Landmark landmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LandmarkPopup(landmark: landmark),
    );
  }
}

class _LandmarkPopup extends StatefulWidget {
  final Landmark landmark;

  const _LandmarkPopup({required this.landmark});

  @override
  State<_LandmarkPopup> createState() => _LandmarkPopupState();
}

class _LandmarkPopupState extends State<_LandmarkPopup> {
  bool isLiked = false;
  double heartScale = 1.0;

  bool isCommentMode = false;
  bool isShareMode = false;

  final List<String> comments = [
    "Incroyable endroit !",
    "J’aimerais tellement y aller 😍",
    "Magnifique photo 🔥",
  ];

  final List<Map<String, dynamic>> accounts = [
    {"name": "Votre story", "icon": Icons.history, "isStory": true},
    {"name": "Alexis", "icon": Icons.person},
    {"name": "Clem", "icon": Icons.person},
    {"name": "Antoine", "icon": Icons.person},
    {"name": "Marie", "icon": Icons.person},
  ];

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: isCommentMode ? 0.85 : 0.50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.22,
            child: PageView.builder(
              itemCount: 5,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      widget.landmark.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.landmark.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Partagé par ${widget.landmark.owner}",
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  "Date : 12 Octobre 2025",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          if (isCommentMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isCommentMode = false),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Commentaires",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: comments
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  c,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      minLines: 1,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ajouter un commentaire...",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.send, color: Colors.white),
                ],
              ),
            ),
          ] else if (isShareMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isShareMode = false),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Partager",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SizedBox(
                      width: 70,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: acc["isStory"] == true
                                ? Colors.orange
                                : Colors.grey,
                            child: Icon(
                              acc["icon"],
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              acc["name"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isLiked = !isLiked;
                        heartScale = 1.3;
                      });
                      await Future.delayed(const Duration(milliseconds: 140));
                      if (!mounted) return;
                      setState(() => heartScale = 1.0);
                    },
                    child: Transform.scale(
                      scale: heartScale,
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      isCommentMode = true;
                      isShareMode = false;
                    }),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      isShareMode = true;
                      isCommentMode = false;
                    }),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapMarkerWidget extends StatelessWidget {
  final Landmark landmark;
  final void Function(Landmark)? onTap;

  const _MapMarkerWidget({required this.landmark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(landmark),
      child: Column(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    "Voyage d'${landmark.owner}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                    bottom: Radius.circular(12),
                  ),
                  child: Image.asset(
                    landmark.image,
                    fit: BoxFit.cover,
                    height: 80,
                    width: 120,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    landmark.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(size: const ui.Size(24, 12), painter: _TrianglePainter()),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
