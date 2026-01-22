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
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      String isoString = dateStr;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        isoString += 'Z';
      }

      final date = DateTime.tryParse(isoString);
      if (date == null) return DateTime.now();

      return date.toLocal();
    }

    return CommentModel(
      id: json['comment_id'] ?? 0,
      content: json['content'] ?? "",
      createdAt: parseDate(json['created_at']?.toString()),
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? "Utilisateur",
      profilePicture: json['profile_picture'] ?? "",
    );
  }
}
