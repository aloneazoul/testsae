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
  
  // NOUVEAU CHAMP
  final bool isLiked; 

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
    this.isLiked = false, // Valeur par défaut
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String? mediaString = json['media_urls']; 
    List<String> images = [];
    if (mediaString != null && mediaString.isNotEmpty) {
      images = mediaString.split(',');
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
      date: json['publication_date'] != null 
          ? DateTime.tryParse(json['publication_date'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      
      // Conversion int (0 ou 1) du SQL vers bool Dart
      isLiked: (json['is_liked'] != null && json['is_liked'] > 0),
    );
  }
}