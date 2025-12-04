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
    this.tripName,
    this.placeName,
    this.cityName,
    this.latitude,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String? mediaString = json['media_urls']; 
    List<String> images = [];
    if (mediaString != null && mediaString.isNotEmpty) {
      images = mediaString.split(',');
    }

    // --- LOGIQUE IDENTIQUE À COMMENT_MODEL ---
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      // 1. Correction du format (remplacer espace par T si nécessaire)
      String isoString = dateStr.replaceFirst(' ', 'T');

      // 2. Si pas de timezone, on ajoute 'Z' pour dire que c'est du UTC
      if (!isoString.endsWith('Z') && !isoString.contains('+')) {
        isoString += 'Z';
      }

      // 3. On parse et on convertit en HEURE LOCALE (.toLocal())
      // C'est ça qui corrige le décalage de 1h
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
      
      // Utilisation de la fonction de parsing corrigée
      date: parseDate(json['publication_date']?.toString()),
      
      isLiked: (json['is_liked'] != null && json['is_liked'] > 0),
      
      // Récupération des infos de voyage et lieu
      tripName: json['trip_title'], 
      placeName: json['place_name'],
      cityName: json['city_name'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
    );
  }
  
  // Helper pour l'affichage du lieu (sans "Lieu épinglé")
  String? get displayLocation {
    if (cityName != null && cityName!.isNotEmpty) return cityName;
    if (placeName != null && placeName!.isNotEmpty) return placeName;
    return null;
  }
}