class CommunityPost {
  final String id;
  final String userId;
  final String content;
  final List<String>? mediaUrls;
  final String? catchLogId;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // User info (joined from profiles)
  final String? userDisplayName;
  final String? userAvatarUrl;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls,
    this.catchLogId,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'] as List)
          : null,
      catchLogId: json['catch_log_id'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userDisplayName: json['user_display_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'catch_log_id': catchLogId,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? mediaUrls,
    String? catchLogId,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userDisplayName,
    String? userAvatarUrl,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      catchLogId: catchLogId ?? this.catchLogId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
