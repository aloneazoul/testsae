import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class Landmark {
  final int id;
  final String name;
  final String image;
  final String owner;
  final Point coords;
  final List<String> images;

  Landmark({
    required this.id,
    required this.name,
    required this.image,
    required this.owner,
    required this.coords,
    required this.images,
  });
}
