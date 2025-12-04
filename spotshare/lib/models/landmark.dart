import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:spotshare/models/post_model.dart';

class Landmark {
  final int id;
  final String name;
  final String image;
  final String owner;
  final Point coords;
  final List<String> images;
  final PostModel post;

  Landmark({
    required this.id,
    required this.name,
    required this.image,
    required this.owner,
    required this.coords,
    required this.images,
    required this.post,
  });
}
