class Booking {
  final String id;
  final String skillId;
  final String skillTitle;
  final String providerId;
  final String providerName;
  final String clientId;
  final String clientName;
  final DateTime bookingDate;
  final DateTime requestDate;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final double price;
  final String? notes;
  final String? location;
  final bool isOnline;

  Booking({
    required this.id,
    required this.skillId,
    required this.skillTitle,
    required this.providerId,
    required this.providerName,
    required this.clientId,
    required this.clientName,
    required this.bookingDate,
    required this.requestDate,
    required this.status,
    required this.price,
    this.notes,
    this.location,
    this.isOnline = false,
  });

  Booking copyWith({
    String? id,
    String? skillId,
    String? skillTitle,
    String? providerId,
    String? providerName,
    String? clientId,
    String? clientName,
    DateTime? bookingDate,
    DateTime? requestDate,
    String? status,
    double? price,
    String? notes,
    String? location,
    bool? isOnline,
  }) {
    return Booking(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      skillTitle: skillTitle ?? this.skillTitle,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      bookingDate: bookingDate ?? this.bookingDate,
      requestDate: requestDate ?? this.requestDate,
      status: status ?? this.status,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
