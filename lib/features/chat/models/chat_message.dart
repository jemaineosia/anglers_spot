class ChatMessage {
  final String id;
  final String channelId;
  final String userId;
  final String content;
  final String? mediaUrl;
  final String? replyTo;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // User info (joined from profiles)
  final String? userDisplayName;
  final String? userAvatarUrl;

  ChatMessage({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.content,
    this.mediaUrl,
    this.replyTo,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      replyTo: json['reply_to'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
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
      'channel_id': channelId,
      'user_id': userId,
      'content': content,
      'media_url': mediaUrl,
      'reply_to': replyTo,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_display_name': userDisplayName,
      'user_avatar_url': userAvatarUrl,
    };
  }

  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);
}
