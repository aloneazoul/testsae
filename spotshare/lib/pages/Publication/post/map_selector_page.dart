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

  Uint8List? pingImageBytes;

  @override
  void initState() {
    super.initState();
    _loadPingImage();
    _initMap();
  }

  void _initMap() {
    const ACCESS_TOKEN =
        'pk.eyJ1IjoiYWxleGlzZHoiLCJhIjoiY21nNmtrcWc4MGUxaTJoczI1cm5jbGZwdCJ9.x10xKnS4jeJGgs3EuWbdUg';
    MapboxOptions.setAccessToken(ACCESS_TOKEN);
  }

  Future<void> _loadPingImage() async {
    final ByteData bytes = await rootBundle.load('assets/ping.png');
    setState(() {
      pingImageBytes = bytes.buffer.asUint8List();
    });
  }

  @override
  void dispose() {
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
          MapWidget(
            styleUri: "mapbox://styles/alexisdz/cmgi1acn6001701s3b4y93lse",
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(2.349, 48.853)),
              zoom: 3,
              bearing: 0,
              pitch: 0,
            ),
            onMapCreated: (map) async {
              _mapboxMap = map;

              await _mapboxMap.gestures.updateSettings(
                GesturesSettings(
                  scrollEnabled: true,
                  pinchToZoomEnabled: true,
                  rotateEnabled: false,
                  pitchEnabled: false,
                  quickZoomEnabled: true,
                ),
              );

              await _mapboxMap.setCamera(CameraOptions(bearing: 0));

              _pointAnnotationManager = await _mapboxMap.annotations
                  .createPointAnnotationManager();
            },
            onTapListener: (MapContentGestureContext ctx) async {
              final point = ctx.point;

              final lon = point.coordinates.lng;
              final lat = point.coordinates.lat;

              selectedLat = lat.toDouble();
              selectedLon = lon.toDouble();

              if (pingImageBytes != null && _pointAnnotationManager != null) {
                if (_pointAnnotation != null) {
                  await _pointAnnotationManager!.delete(_pointAnnotation!);
                  _pointAnnotation = null;
                }

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
          ),

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
