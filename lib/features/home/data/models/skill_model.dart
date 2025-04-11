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
    String? location,
    String? userId,
    String? phoneNumber,
    Map<String, dynamic>? address,
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
          location: location,
          userId: userId,
          phoneNumber: phoneNumber,
          address: address,
        );

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    // Handle address field if present
    Map<String, dynamic>? addressData;
    if (json.containsKey('address') && json['address'] != null) {
      addressData = Map<String, dynamic>.from(json['address'] as Map);
    }

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
      location: json['location'] as String?,
      userId: json['user_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: addressData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
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

    // Add optional fields if they exist
    if (location != null) data['location'] = location;
    if (userId != null) data['user_id'] = userId;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (address != null) data['address'] = address;

    return data;
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
      location: skill.location,
      userId: skill.userId,
      phoneNumber: skill.phoneNumber,
      address: skill.address,
    );
  }
}
