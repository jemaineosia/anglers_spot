class CatchLog {
  final String id;
  final String userId;
  final String species;
  final double? weight; // kg
  final double? length; // cm
  final String? bait;
  final String? environment; // beach, rocks, offshore, etc
  final String? notes;
  final double? lat;
  final double? lon;
  final String? locationName;
  final String? photoUrl;
  final DateTime createdAt;

  CatchLog({
    required this.id,
    required this.userId,
    required this.species,
    this.weight,
    this.length,
    this.bait,
    this.environment,
    this.notes,
    this.lat,
    this.lon,
    this.locationName,
    this.photoUrl,
    required this.createdAt,
  });

  factory CatchLog.fromJson(Map<String, dynamic> json) => CatchLog(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    species: json['species'] as String,
    weight: (json['weight'] as num?)?.toDouble(),
    length: (json['length'] as num?)?.toDouble(),
    bait: json['bait'] as String?,
    environment: json['environment'] as String?,
    notes: json['notes'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lon: (json['lon'] as num?)?.toDouble(),
    locationName: json['location_name'] as String?,
    photoUrl: json['photo_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'species': species,
    'weight': weight,
    'length': length,
    'bait': bait,
    'environment': environment,
    'notes': notes,
    'lat': lat,
    'lon': lon,
    'location_name': locationName,
    'photo_url': photoUrl,
  };
}
