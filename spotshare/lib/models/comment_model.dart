class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String profilePicture;
  final String content;
  final DateTime createdAt;
  final int likes;
  final bool isLiked;
  final String? parentCommentId;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.profilePicture,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
    this.parentCommentId,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Gestion robuste de la date pour éviter le bug "1h"
    DateTime parseDate(dynamic dateRaw) {
      if (dateRaw == null) return DateTime.now();
      String dateStr = dateRaw.toString();
      // Si la date n'a pas de 'Z' ou d'offset, on assume que c'est du UTC venant du serveur
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    }

    return CommentModel(
      id: json['comment_id']?.toString() ?? json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      username: json['username'] ?? json['pseudo'] ?? 'Utilisateur',
      profilePicture: json['profile_picture'] ?? json['img'] ?? '',
      content: json['content'] ?? json['text'] ?? '',
      createdAt: parseDate(json['created_at']),
      likes: json['likes_count'] ?? json['likes'] ?? 0,
      isLiked: (json['is_liked'] == true || json['is_liked'] == 1),
      parentCommentId: json['parent_comment_id']?.toString(),
    );
  }

  CommentModel copyWith({
    int? likes,
    bool? isLiked,
    String? parentCommentId,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      profilePicture: profilePicture,
      content: content,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}