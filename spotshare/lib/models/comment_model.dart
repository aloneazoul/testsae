// lib/models/comment_model.dart

class CommentModel {
  final int id;
  final String content;
  final DateTime createdAt;
  final int userId;
  final String username;
  final String profilePicture;

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.username,
    required this.profilePicture,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['comment_id'],
      content: json['content'],
      // Gestion safe de la date
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      userId: json['user_id'],
      username: json['username'] ?? "Utilisateur",
      profilePicture: json['profile_picture'] ?? "",
    );
  }
}