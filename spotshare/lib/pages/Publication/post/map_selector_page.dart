import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapSelectorPage extends StatefulWidget {
  const MapSelectorPage({super.key});

  @override
  State<MapSelectorPage> createState() => _MapSelectorPageState();
}

class _MapSelectorPageState extends State<MapSelectorPage> {
  late MapboxMap _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _pointAnnotation;

  double? selectedLat;
  double? selectedLon;

  // Image bytes for the ping marker
  Uint8List? pingImageBytes;

  @override
  void initState() {
    super.initState();
    _loadPingImage();
  }

  Future<void> _loadPingImage() async {
    // Charge l'image depuis les assets
    final ByteData bytes = await rootBundle.load('assets/ping.png');
    setState(() {
      pingImageBytes = bytes.buffer.asUint8List();
    });
  }

  @override
  void dispose() {
    // supprimer le manager lors du dispose
    if (_pointAnnotationManager != null) {
      _mapboxMap.annotations.removeAnnotationManager(_pointAnnotationManager!);
      _pointAnnotationManager = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- MapWidget (Mapbox) ---
          MapWidget(
            styleUri: "mapbox://styles/mapbox/streets-v12",
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(2.349, 48.853)),
              zoom: 3, // zoom initial
              bearing: 0, // orientation nord
              pitch: 0,
            ),
            // callback quand le controller est prêt
            onMapCreated: (map) async {
              _mapboxMap = map;

              // Paramètres gestures : zoom/pan ok, rotation/pitch désactivés
              await _mapboxMap.gestures.updateSettings(
                GesturesSettings(
                  scrollEnabled: true,
                  pinchToZoomEnabled: true, // pinch-to-zoom
                  rotateEnabled: false, // interdit la rotation
                  pitchEnabled: false, // interdit le pitch
                  quickZoomEnabled: true,
                ),
              );

              // Forcer orientation nord au démarrage
              await _mapboxMap.setCamera(CameraOptions(bearing: 0));

              // Créer le manager d'annotations (point annotations)
              _pointAnnotationManager = await _mapboxMap.annotations
                  .createPointAnnotationManager();

              // IMPORTANT : onTapListener sur MapWidget — reçoit MapContentGestureContext
              // quand l'utilisateur tape sur la carte.
              // On utiliserá la callback fournie au MapWidget plus bas via key trick :
              // Ici on s'assure simplement que le manager est prêt.
            },
            // onTapListener est appelé quand l'utilisateur tape (clic) sur la carte.
            // La signature reçoit un MapContentGestureContext.
            onTapListener: (MapContentGestureContext ctx) async {
              final point = ctx.point;

              final lon = point.coordinates.lng;
              final lat = point.coordinates.lat;

              selectedLat = lat.toDouble();
              selectedLon = lon.toDouble();

              if (pingImageBytes != null && _pointAnnotationManager != null) {
                // Supprime l'ancien ping si il existe
                if (_pointAnnotation != null) {
                  await _pointAnnotationManager!.delete(_pointAnnotation!);
                  _pointAnnotation = null;
                }

                // Crée le ping à la nouvelle position
                final options = PointAnnotationOptions(
                  geometry: Point(coordinates: Position(lon, lat)),
                  image: pingImageBytes,
                  iconSize: 0.4,
                  iconOffset: [0.0, -20.0],
                );

                _pointAnnotation = await _pointAnnotationManager!.create(
                  options,
                );
              }

              setState(() {});
            },
            // facultatif : onStyleLoadedListener / onCameraChangeListener si besoin.
          ),

          // --- Bouton fermer ---
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // --- Bouton confirmer ---
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(18),
              ),
              onPressed: (selectedLat == null || selectedLon == null)
                  ? null
                  : () {
                      Navigator.pop(context, {
                        "lat": selectedLat,
                        "lon": selectedLon,
                      });
                    },
              child: const Text("Confirmer la localisation"),
            ),
          ),

          // --- (Optionnel) Affichage overlay lat/lon si tu veux voir les coordonnées ---
          if (selectedLat != null && selectedLon != null)
            Positioned(
              top: 110,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "lat: ${selectedLat!.toStringAsFixed(6)}, lon: ${selectedLon!.toStringAsFixed(6)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
