class ChatChannel {
  final String id;
  final String name;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final bool isActive;
  final int memberCount;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;

  ChatChannel({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.memberCount = 0,
    this.lastMessageAt,
    this.lastMessageContent,
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      memberCount: json['member_count'] as int? ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageContent: json['last_message_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'member_count': memberCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_content': lastMessageContent,
    };
  }
}
