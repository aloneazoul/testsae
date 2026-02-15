class StoryItem {
  final int storyId;
  final String mediaUrl;
  final String mediaType; // 'IMAGE' ou 'VIDEO'
  final String? caption;
  final DateTime? date; // AJOUTÉ : Nécessaire pour le StoryPlayer
  bool isViewed;

  StoryItem({
    required this.storyId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.date,
    this.isViewed = false,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      storyId: json['story_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      caption: json['caption'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      isViewed: json['is_viewed'] == true,
    );
  }
}

class UserStoryGroup {
  final int userId;
  final String username;
  final String? profilePicture;
  final bool isMine;
  final bool allSeen;
  final List<StoryItem> stories;

  UserStoryGroup({
    required this.userId,
    required this.username,
    this.profilePicture,
    required this.isMine,
    required this.allSeen,
    required this.stories,
  });

  factory UserStoryGroup.fromJson(Map<String, dynamic> json) {
    var list = json['stories'] as List;
    List<StoryItem> storyList = list.map((i) => StoryItem.fromJson(i)).toList();

    return UserStoryGroup(
      userId: json['user_id'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      isMine: json['is_mine'] == true,
      allSeen: json['all_seen'] ?? true,
      stories: storyList,
    );
  }
}