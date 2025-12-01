// lib/models/post_model.dart

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String profileImageUrl;
  final List<String> imageUrls; // Liste d'images (car ton PostCard gère un carrousel)
  final String caption;
  final int likes;
  final int comments;
  final DateTime date;

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
  });

  // Le traducteur : JSON (API) -> Objet Dart (Appli)
  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Récupération de la chaîne brute (ex: "url1,url2")
    String? mediaString = json['media_urls']; 
    List<String> images = [];

    // Si on a des médias, on coupe la chaîne à chaque virgule
    if (mediaString != null && mediaString.isNotEmpty) {
      images = mediaString.split(',');
    }

    return PostModel(
      id: json['post_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['username'] ?? "Utilisateur",
      profileImageUrl: json['profile_picture'] ?? "",
      
      // 👇 On donne la liste complète ici
      imageUrls: images, 
      
      caption: json['post_description'] ?? "",
      likes: json['likes_count'] ?? 0,
      comments: json['comments_count'] ?? 0,
      date: json['publication_date'] != null 
          ? DateTime.tryParse(json['publication_date'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}