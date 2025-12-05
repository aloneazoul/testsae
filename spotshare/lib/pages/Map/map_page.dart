import 'dart:async';
import 'dart:math';
import 'package:spotshare/models/landmark_model.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:spotshare/models/post_model.dart';
import 'package:spotshare/services/post_service.dart';
import 'package:spotshare/services/trip_service.dart';
import 'dart:ui' as ui;

import 'package:spotshare/services/user_service.dart';
import 'package:spotshare/widgets/post_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.data = 1, this.trip = null});
  final int data;
  final dynamic trip;

  @override
  State<MapPage> createState() => _DarkMapboxWidgetState();
}

class _DarkMapboxWidgetState extends State<MapPage> {
  late MapboxMap _mapboxMap;
  bool _mapReady = false;

  final List<Landmark> _landmarks = []; // Typé proprement

  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _initMap();
    loadLandmarks();
  }

  void _initMap() {
    const ACCESS_TOKEN =
        'pk.eyJ1IjoiYWxleGlzZHoiLCJhIjoiY21nNmtrcWc4MGUxaTJoczI1cm5jbGZwdCJ9.x10xKnS4jeJGgs3EuWbdUg';
    MapboxOptions.setAccessToken(ACCESS_TOKEN);
  }

  Future<void> loadLandmarks() async {
    _landmarks.clear(); 
    
    if (widget.data == 1) {
      await _loadFeedLandmarks();
    } else if (widget.data == 2 && widget.trip != null) {
      await _loadTripLandmarks(widget.trip);
    }

    if (!mounted) return;
    setState(() {});

    if (_mapReady && _landmarks.isNotEmpty) {
      await _mapboxMap.setCamera(
        CameraOptions(
          center: _landmarks.first.coords,
          zoom: 1.5,
        ),
      );
      await _updateAllMarkerPositions();
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    setState(() => _mapReady = true);

    if (_landmarks.isNotEmpty) {
      await _mapboxMap.setCamera(
        CameraOptions(center: _landmarks.first.coords, zoom: 1.5),
      );
    }

    await _updateAllMarkerPositions();

    await _mapboxMap.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );
  }

  Future<void> _loadTripLandmarks(dynamic trip) async {
    final user = await getMyProfile();
    final tripService = TripService();
    final postService = PostService();

    if (trip == null || trip["trip_id"] == null) return;

    final posts = await tripService.getTripPosts(trip["trip_id"]);

    for (final post in posts) {
      final media = await postService.getFirstMediaTripPosts(post["post_id"]);
      final mediaUrl = media?["media_url"] ?? "";

      final List<dynamic> medias = await postService.getMediaTripPosts(post["post_id"]);
      final List<String> mediaUrls = medias.map((m) => m["media_url"] as String).toList();

      final title = post["post_title"] ?? "Sans titre";
      final lon = post["longitude"];
      final lat = post["latitude"];
      final vrai_post = PostModel.fromJson(post);

      if (lon == null || lat == null) continue;

      _landmarks.add(
        Landmark(
          id: post["post_id"],
          name: title,
          image: mediaUrl,
          owner: post["username"] ?? "Utilisateur",
          coords: Point(
            coordinates: Position(
              lon is double ? lon : double.tryParse(lon.toString()) ?? 0,
              lat is double ? lat : double.tryParse(lat.toString()) ?? 0,
            ),
          ),
          images: mediaUrls,
          post: vrai_post,
        ),
      );
    }
  }

  Future<void> _loadFeedLandmarks() async {
    final PostService _postService = PostService();
    final user = await getMyProfile();

    final posts = await _postService.getDiscoveryFeed();

    for (final post in posts) {
      final media = await _postService.getFirstMediaTripPosts(post["post_id"]);
      final mediaUrl = media?["media_url"] ?? "";

      final List<dynamic> medias = await _postService.getMediaTripPosts(post["post_id"]);
      final List<String> mediaUrls = medias.map((m) => m["media_url"] as String).toList();

      final title = post["post_title"] ?? "Sans titre";
      final lon = post["longitude"];
      final lat = post["latitude"];
      final vrai_post = PostModel.fromJson(post);

      if (lon == null || lat == null) continue;

      _landmarks.add(
        Landmark(
          id: post["post_id"],
          name: title,
          image: mediaUrl,
          owner: post["username"] ?? "Utilisateur",
          coords: Point(
            coordinates: Position(
              lon is double ? lon : double.tryParse(lon.toString()) ?? 0,
              lat is double ? lat : double.tryParse(lat.toString()) ?? 0,
            ),
          ),
          images: mediaUrls,
          post: vrai_post,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            styleUri: "mapbox://styles/alexisdz/cmgi1acn6001701s3b4y93lse",
            cameraOptions: CameraOptions(
              center: _landmarks.isEmpty
                  ? Point(coordinates: Position(0, 0))
                  : _landmarks.first.coords,
              zoom: 1.5,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: (CameraChangedEventData data) async {
              if (_mapReady) await _updateAllMarkerPositions();
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FlightPathPainter(_positions, _landmarks),
              ),
            ),
          ),
          ..._positions.entries.map((entry) {
            final lm = _landmarks.firstWhere((l) => l.id.toString() == entry.key);
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
    final camPos = camera.center.coordinates;
    final newPositions = <String, Offset>{};

    for (final lm in _landmarks) {
      try {
        if (!_isVisibleOnGlobe(camPos, lm.coords.coordinates)) continue;
        final screenCoords = await _mapboxMap.pixelForCoordinate(lm.coords);

        if (screenCoords.x.isNaN || screenCoords.y.isNaN || screenCoords.x < 0 || screenCoords.y < 0 || screenCoords.x > MediaQuery.of(context).size.width || screenCoords.y > MediaQuery.of(context).size.height)
          continue;

        newPositions[lm.id.toString()] = Offset(screenCoords.x, screenCoords.y);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _positions..clear()..addAll(newPositions);
    });
  }

  // 🔥 UPDATE ICI : On passe un callback pour récupérer les likes/comments
  void _showLandmarkDetails(Landmark landmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LandmarkPopup(
        landmark: landmark,
        // ✅ C'est ici qu'on met à jour la donnée LOCALE de la map
        onPostUpdated: (updatedPost) {
          setState(() {
            final index = _landmarks.indexWhere((l) => l.id == landmark.id);
            if (index != -1) {
              // On remplace le landmark par une version à jour (Like activé, etc.)
              _landmarks[index] = landmark.copyWith(post: updatedPost);
            }
          });
        },
      ),
    );
  }
}

class _LandmarkPopup extends StatefulWidget {
  final Landmark landmark;
  final Function(PostModel) onPostUpdated;

  const _LandmarkPopup({required this.landmark, required this.onPostUpdated});

  @override
  State<_LandmarkPopup> createState() => _LandmarkPopupState();
}

class _LandmarkPopupState extends State<_LandmarkPopup> {
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.landmark.post;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.90,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(widget.landmark.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      PostCard(
                        post: _currentPost,
                        textSize: 13,
                        isOwner: false,
                        
                        // ✅ Quand on like dans la popup
                        onLikeChanged: (isLiked, newLikeCount) {
                          final updated = _currentPost.copyWith(isLiked: isLiked, likes: newLikeCount);
                          setState(() => _currentPost = updated);
                          widget.onPostUpdated(updated); // On prévient la Map tout de suite
                        },

                        // ✅ Quand on commente
                        onCommentAdded: (newCommentCount) {
                          final updated = _currentPost.copyWith(comments: newCommentCount);
                          setState(() => _currentPost = updated);
                          widget.onPostUpdated(updated); // On prévient la Map
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... Les classes _MapMarkerWidget, _TrianglePainter et FlightPathPainter restent identiques ...
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("${landmark.owner}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14), textAlign: TextAlign.center),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12)),
                  child: (landmark.image.startsWith('http')
                      ? Image.network(landmark.image, fit: BoxFit.cover, height: 80, width: 120, errorBuilder: (_, __, ___) => Container(color: Colors.grey, height: 80, width: 120, child: const Icon(Icons.broken_image)))
                      : Image.asset(landmark.image, fit: BoxFit.cover, height: 80, width: 120)),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(landmark.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14), textAlign: TextAlign.center),
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
    final path = Path()..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlightPathPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List landmarks;
  final Paint linePaint;
  final Paint shadowPaint;

  FlightPathPainter(this.positions, this.landmarks)
    : linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round,
      shadowPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..color = Colors.black26;

  @override
  void paint(Canvas canvas, ui.Size size) {
    final pts = <Offset>[];
    for (final lm in landmarks) {
      final key = lm.id.toString();
      if (positions.containsKey(key)) pts.add(positions[key]!);
    }
    if (pts.length < 2) return;
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      final control = mid + (Offset(-(p1.dy - p0.dy), p1.dx - p0.dx) / sqrt(pow(p1.dx - p0.dx, 2) + pow(p1.dy - p0.dy, 2))) * (sqrt(pow(p1.dx - p0.dx, 2) + pow(p1.dy - p0.dy, 2)) / 4).clamp(20.0, 120.0);
      final path = Path()..moveTo(p0.dx, p0.dy)..quadraticBezierTo(control.dx, control.dy, p1.dx, p1.dy);
      canvas.drawPath(path, shadowPaint..color = Colors.black26);
      canvas.drawPath(path, linePaint..color = Colors.white);
    }
    for (int i = 0; i < pts.length - 1; i++) {
      final mx = (pts[i].dx + pts[i + 1].dx) / 2;
      final my = (pts[i].dy + pts[i + 1].dy) / 2;
      canvas.save();
      canvas.translate(mx, my);
      canvas.rotate(atan2(pts[i + 1].dy - pts[i].dy, pts[i + 1].dx - pts[i].dx));
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant FlightPathPainter oldDelegate) => oldDelegate.positions != positions || oldDelegate.landmarks != landmarks;
}