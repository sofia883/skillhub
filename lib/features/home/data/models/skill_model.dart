import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillModel extends Skill {
  SkillModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
    required double rating,
    int reviewCount = 0,
    required String provider,
    required String imageUrl,
    List<String> experienceImages = const [],
    String? providerImageUrl,
    required DateTime createdAt,
    bool isFeatured = false,
    String? location,
    String? userId,
    String? phoneNumber,
    Map<String, dynamic>? address,
    bool isOnline = false,
    DateTime? lastSeen,
    bool isVerified = false,
    double? hourlyRate,
    String? education,
    String? experience,
    List<String>? certifications,
    List<String>? languages,
    String? availability,
  }) : super(
          id: id,
          title: title,
          description: description,
          category: category,
          price: price,
          rating: rating,
          reviewCount: reviewCount,
          provider: provider,
          imageUrl: imageUrl,
          experienceImages: experienceImages,
          providerImageUrl: providerImageUrl,
          createdAt: createdAt,
          isFeatured: isFeatured,
          location: location,
          userId: userId,
          phoneNumber: phoneNumber,
          address: address,
          isOnline: isOnline,
          lastSeen: lastSeen,
          isVerified: isVerified,
          hourlyRate: hourlyRate,
          education: education,
          experience: experience,
          certifications: certifications,
          languages: languages,
          availability: availability,
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
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      provider: json['provider'] as String,
      imageUrl: json['imageUrl'] as String,
      experienceImages: List<String>.from(json['experienceImages'] ?? []),
      providerImageUrl: json['providerImageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      location: json['location'] as String?,
      userId: json['userId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: addressData,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      education: json['education'] as String?,
      experience: json['experience'] as String?,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : null,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      availability: json['availability'] as String?,
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
      'reviewCount': reviewCount,
      'provider': provider,
      'imageUrl': imageUrl,
      'experienceImages': experienceImages,
      'providerImageUrl': providerImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFeatured': isFeatured,
      'location': location,
      'userId': userId,
      'phoneNumber': phoneNumber,
      'address': address,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isVerified': isVerified,
      'hourlyRate': hourlyRate,
      'education': education,
      'experience': experience,
      'certifications': certifications,
      'languages': languages,
      'availability': availability,
    };

    // Add optional fields if they exist
    if (location != null) data['location'] = location;
    if (userId != null) data['userId'] = userId;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
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
      reviewCount: skill.reviewCount,
      provider: skill.provider,
      imageUrl: skill.imageUrl,
      experienceImages: skill.experienceImages,
      providerImageUrl: skill.providerImageUrl,
      createdAt: skill.createdAt,
      isFeatured: skill.isFeatured,
      location: skill.location,
      userId: skill.userId,
      phoneNumber: skill.phoneNumber,
      address: skill.address,
      isOnline: skill.isOnline,
      lastSeen: skill.lastSeen,
      isVerified: skill.isVerified,
      hourlyRate: skill.hourlyRate,
      education: skill.education,
      experience: skill.experience,
      certifications: skill.certifications,
      languages: skill.languages,
      availability: skill.availability,
    );
  }
}
