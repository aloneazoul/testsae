class PostModel {
  final String id;
  final String userId;
  final String userName;
  final List<String> imageUrls;
  final String caption;
  final int likes;
  final int comments;
  final DateTime date;
  final String profileImageUrl; // photo de profil fixe

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrls,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.date,
    required this.profileImageUrl, // obligatoire maintenant
  });
}
