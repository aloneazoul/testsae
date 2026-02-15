import 'package:spotshare/models/post_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String profileImageUrl;
  final List<String> imageUrls;
  final String caption;
  final int likes;
  final int comments;
  final DateTime date;

  final bool isLiked;

  // NOUVEAU : Type de post (POST ou MEMORY)
  final String postType;

  // Champs pour le contexte (Voyage / Lieu)
  final String? tripName;
  final String? placeName;
  final String? cityName;
  final double? latitude;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.profileImageUrl,
    required this.imageUrls,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.date,
    this.isLiked = false,
    this.postType = "POST", // Par défaut
    this.tripName,
    this.placeName,
    this.cityName,
    this.latitude,
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? profileImageUrl,
    List<String>? imageUrls,
    String? caption,
    int? likes,
    int? comments,
    DateTime? date,
    bool? isLiked,
    String? postType,
    String? tripName,
    String? placeName,
    String? cityName,
    double? latitude,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      date: date ?? this.date,
      isLiked: isLiked ?? this.isLiked,
      postType: postType ?? this.postType,
      tripName: tripName ?? this.tripName,
      placeName: placeName ?? this.placeName,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String? mediaString = json['media_urls'];
    List<String> images = [];
    if (mediaString != null && mediaString.isNotEmpty) {
      images = mediaString.split(',');
    }

    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      String isoString = dateStr.replaceFirst(' ', 'T');

      if (!isoString.endsWith('Z') && !isoString.contains('+')) {
        isoString += 'Z';
      }

      final date = DateTime.tryParse(isoString);
      if (date == null) return DateTime.now();

      return date.toLocal();
    }

    return PostModel(
      id: json['post_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['username'] ?? "Utilisateur",
      profileImageUrl: json['profile_picture'] ?? "",
      imageUrls: images,
      caption: json['post_description'] ?? "",
      likes: json['likes_count'] ?? 0,
      comments: json['comments_count'] ?? 0,

      date: parseDate(json['publication_date']?.toString()),

      isLiked: (json['is_liked'] != null && json['is_liked'] > 0),
      postType: json['post_type'] ?? "POST",

      tripName: json['trip_title'],
      placeName: json['place_name'],
      cityName: json['city_name'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
    );
  }

  String? get displayLocation {
    if (cityName != null && cityName!.isNotEmpty) return cityName;
    if (placeName != null && placeName!.isNotEmpty) return placeName;
    return null;
  }
}