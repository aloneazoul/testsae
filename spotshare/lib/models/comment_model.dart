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
    // Fonction utilitaire pour parser la date correctement
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();

      // Si la date arrive sans indicateur de timezone (ex: "2023-11-02T15:00:00"),
      // Dart la considère par défaut comme locale. 
      // On ajoute 'Z' à la fin pour lui dire "C'est du UTC !".
      String isoString = dateStr;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        isoString += 'Z';
      }

      // On parse, puis on convertit en heure locale du téléphone
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