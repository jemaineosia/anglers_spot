class MarketplaceItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String? category;
  final String? condition;
  final String? location;
  final List<String>? imageUrls;
  final bool isSold;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewsCount;

  // User info (joined from profiles)
  final String? userDisplayName;
  final String? userAvatarUrl;

  MarketplaceItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    this.category,
    this.condition,
    this.location,
    this.imageUrls,
    this.isSold = false,
    required this.createdAt,
    this.updatedAt,
    this.viewsCount = 0,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] is String)
          ? double.parse(json['price'] as String)
          : (json['price'] as num).toDouble(),
      category: json['category'] as String?,
      condition: json['condition'] as String?,
      location: json['location'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      isSold: json['is_sold'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      viewsCount: json['views_count'] as int? ?? 0,
      userDisplayName: json['user_display_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'location': location,
      'image_urls': imageUrls,
      'is_sold': isSold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'views_count': viewsCount,
      'user_display_name': userDisplayName,
      'user_avatar_url': userAvatarUrl,
    };
  }

  MarketplaceItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    String? location,
    List<String>? imageUrls,
    bool? isSold,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewsCount,
    String? userDisplayName,
    String? userAvatarUrl,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      isSold: isSold ?? this.isSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewsCount: viewsCount ?? this.viewsCount,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
