class Skill {
  String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final String provider;
  final String imageUrl;
  final DateTime createdAt;
  final bool isFeatured;
  final String? location; // Location field
  final String? userId; // UserId field for security rules
  final String? phoneNumber; // Added phone number field
  final Map<String, dynamic>? address; // Structured address field

  Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.provider,
    required this.imageUrl,
    required this.createdAt,
    this.isFeatured = false,
    this.location,
    this.userId,
    this.phoneNumber,
    this.address,
  });

  Skill copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? rating,
    String? provider,
    String? imageUrl,
    DateTime? createdAt,
    bool? isFeatured,
    String? location,
    String? userId,
    String? phoneNumber,
    Map<String, dynamic>? address,
  }) {
    return Skill(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      provider: provider ?? this.provider,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}
