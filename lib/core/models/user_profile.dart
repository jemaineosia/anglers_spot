import 'user_role.dart';

class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Stats
  final int totalCatches;
  final int totalPosts;
  final int followers;
  final int following;

  // Settings
  final bool isPublicProfile;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.role = UserRole.user,
    required this.createdAt,
    this.updatedAt,
    this.totalCatches = 0,
    this.totalPosts = 0,
    this.followers = 0,
    this.following = 0,
    this.isPublicProfile = true,
    this.preferences,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String?,
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    bio: json['bio'] as String?,
    role: UserRole.fromString(json['role'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    totalCatches: (json['total_catches'] as int?) ?? 0,
    totalPosts: (json['total_posts'] as int?) ?? 0,
    followers: (json['followers'] as int?) ?? 0,
    following: (json['following'] as int?) ?? 0,
    isPublicProfile: (json['is_public_profile'] as bool?) ?? true,
    preferences: json['preferences'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'role': role.value,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'total_catches': totalCatches,
    'total_posts': totalPosts,
    'followers': followers,
    'following': following,
    'is_public_profile': isPublicProfile,
    'preferences': preferences,
  };

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    UserRole? role,
    int? totalCatches,
    int? totalPosts,
    int? followers,
    int? following,
    bool? isPublicProfile,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      totalCatches: totalCatches ?? this.totalCatches,
      totalPosts: totalPosts ?? this.totalPosts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
      preferences: preferences ?? this.preferences,
    );
  }

  String get displayNameOrEmail => displayName ?? email ?? 'Anonymous User';
}
