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
    );
  }
}
