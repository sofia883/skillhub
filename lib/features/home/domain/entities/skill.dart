class Skill {
  String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int reviewCount;
  final String provider;
  final String imageUrl;
  final List<String> experienceImages; // Added for multiple experience images
  final String? providerImageUrl; // Added for provider profile image
  final DateTime createdAt;
  final bool isFeatured;
  final String? location; // Location field
  final String? userId; // UserId field for security rules
  final String? phoneNumber; // Added phone number field
  final Map<String, dynamic>? address; // Structured address field
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;
  final double? hourlyRate;
  final String? education;
  final String? experience;
  final List<String>? certifications;
  final List<String>? languages;
  final String? availability;

  Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    this.reviewCount = 0,
    required this.provider,
    required this.imageUrl,
    this.experienceImages = const [],
    this.providerImageUrl,
    required this.createdAt,
    this.isFeatured = false,
    this.location,
    this.userId,
    this.phoneNumber,
    this.address,
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
    this.hourlyRate,
    this.education,
    this.experience,
    this.certifications,
    this.languages,
    this.availability,
  });

  Skill copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? rating,
    int? reviewCount,
    String? provider,
    String? imageUrl,
    List<String>? experienceImages,
    String? providerImageUrl,
    DateTime? createdAt,
    bool? isFeatured,
    String? location,
    String? userId,
    String? phoneNumber,
    Map<String, dynamic>? address,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
    double? hourlyRate,
    String? education,
    String? experience,
    List<String>? certifications,
    List<String>? languages,
    String? availability,
  }) {
    return Skill(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      provider: provider ?? this.provider,
      imageUrl: imageUrl ?? this.imageUrl,
      experienceImages: experienceImages ?? this.experienceImages,
      providerImageUrl: providerImageUrl ?? this.providerImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      location: location ?? this.location,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      certifications: certifications ?? this.certifications,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
    );
  }
}
