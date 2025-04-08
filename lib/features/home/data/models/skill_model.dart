import 'package:skill_hub/features/home/domain/entities/skill.dart';

class SkillModel extends Skill {
  SkillModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
    required double rating,
    required String provider,
    required String imageUrl,
    required DateTime createdAt,
    bool isFeatured = false,
  }) : super(
          id: id,
          title: title,
          description: description,
          category: category,
          price: price,
          rating: rating,
          provider: provider,
          imageUrl: imageUrl,
          createdAt: createdAt,
          isFeatured: isFeatured,
        );

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      provider: json['provider'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'provider': provider,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_featured': isFeatured,
    };
  }

  factory SkillModel.fromEntity(Skill skill) {
    return SkillModel(
      id: skill.id,
      title: skill.title,
      description: skill.description,
      category: skill.category,
      price: skill.price,
      rating: skill.rating,
      provider: skill.provider,
      imageUrl: skill.imageUrl,
      createdAt: skill.createdAt,
      isFeatured: skill.isFeatured,
    );
  }
}
