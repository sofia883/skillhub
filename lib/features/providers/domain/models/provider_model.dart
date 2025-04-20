import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  final String id;
  final String name;
  final String? profileImage;
  final String? location;
  final String description;
  final List<String> skills;
  final List<String> experienceImages;
  final double rating;
  final int reviewCount;
  final DateTime joinedDate;
  final bool isVerified;
  final Map<String, dynamic> availability;
  final String? about;
  final Map<String, dynamic> socialLinks;
  final List<String> certificates;
  final bool isOnline;
  final DateTime? lastSeen;

  ProviderModel({
    required this.id,
    required this.name,
    this.profileImage,
    this.location,
    required this.description,
    required this.skills,
    required this.experienceImages,
    required this.rating,
    required this.reviewCount,
    required this.joinedDate,
    required this.isVerified,
    required this.availability,
    this.about,
    required this.socialLinks,
    required this.certificates,
    required this.isOnline,
    this.lastSeen,
  });

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProviderModel(
      id: doc.id,
      name: data['name'] ?? '',
      profileImage: data['profileImage'],
      location: data['location'],
      description: data['description'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      experienceImages: List<String>.from(data['experienceImages'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      joinedDate:
          (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      availability: Map<String, dynamic>.from(data['availability'] ?? {}),
      about: data['about'],
      socialLinks: Map<String, dynamic>.from(data['socialLinks'] ?? {}),
      certificates: List<String>.from(data['certificates'] ?? []),
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profileImage': profileImage,
      'location': location,
      'description': description,
      'skills': skills,
      'experienceImages': experienceImages,
      'rating': rating,
      'reviewCount': reviewCount,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'isVerified': isVerified,
      'availability': availability,
      'about': about,
      'socialLinks': socialLinks,
      'certificates': certificates,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? profileImage,
    String? location,
    String? description,
    List<String>? skills,
    List<String>? experienceImages,
    double? rating,
    int? reviewCount,
    DateTime? joinedDate,
    bool? isVerified,
    Map<String, dynamic>? availability,
    String? about,
    Map<String, dynamic>? socialLinks,
    List<String>? certificates,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      experienceImages: experienceImages ?? this.experienceImages,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      joinedDate: joinedDate ?? this.joinedDate,
      isVerified: isVerified ?? this.isVerified,
      availability: availability ?? this.availability,
      about: about ?? this.about,
      socialLinks: socialLinks ?? this.socialLinks,
      certificates: certificates ?? this.certificates,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
