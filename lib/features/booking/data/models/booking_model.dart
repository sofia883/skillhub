import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_hub/features/booking/domain/entities/booking.dart';

class BookingModel extends Booking {
  BookingModel({
    required String id,
    required String skillId,
    required String skillTitle,
    required String providerId,
    required String providerName,
    required String clientId,
    required String clientName,
    required DateTime bookingDate,
    required DateTime requestDate,
    required String status,
    required double price,
    String? notes,
    String? location,
    bool isOnline = false,
  }) : super(
          id: id,
          skillId: skillId,
          skillTitle: skillTitle,
          providerId: providerId,
          providerName: providerName,
          clientId: clientId,
          clientName: clientName,
          bookingDate: bookingDate,
          requestDate: requestDate,
          status: status,
          price: price,
          notes: notes,
          location: location,
          isOnline: isOnline,
        );

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      skillId: json['skillId'] as String,
      skillTitle: json['skillTitle'] as String,
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      bookingDate: (json['bookingDate'] as Timestamp).toDate(),
      requestDate: (json['requestDate'] as Timestamp).toDate(),
      status: json['status'] as String,
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skillId': skillId,
      'skillTitle': skillTitle,
      'providerId': providerId,
      'providerName': providerName,
      'clientId': clientId,
      'clientName': clientName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status,
      'price': price,
      'notes': notes,
      'location': location,
      'isOnline': isOnline,
    };
  }

  factory BookingModel.fromEntity(Booking booking) {
    return BookingModel(
      id: booking.id,
      skillId: booking.skillId,
      skillTitle: booking.skillTitle,
      providerId: booking.providerId,
      providerName: booking.providerName,
      clientId: booking.clientId,
      clientName: booking.clientName,
      bookingDate: booking.bookingDate,
      requestDate: booking.requestDate,
      status: booking.status,
      price: booking.price,
      notes: booking.notes,
      location: booking.location,
      isOnline: booking.isOnline,
    );
  }
}
