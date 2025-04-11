import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_hub/features/booking/data/models/booking_model.dart';
import 'package:skill_hub/features/booking/domain/entities/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Local cache for offline support
  List<Booking> _localBookings = [];
  bool _isOfflineMode = false;

  // Initialize repository
  Future<void> init() async {
    await _loadLocalBookings();
    _checkConnectivity();
  }

  // Check if Firebase is available
  Future<bool> _checkConnectivity() async {
    try {
      await _firestore
          .collection('test_collection')
          .doc('test_document')
          .set({'timestamp': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 3));
      _isOfflineMode = false;
      return true;
    } catch (e) {
      print('Firebase unavailable: $e');
      _isOfflineMode = true;
      return false;
    }
  }

  // Load bookings from local storage
  Future<void> _loadLocalBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString('local_bookings');
      if (bookingsJson != null) {
        final List<dynamic> decoded = jsonDecode(bookingsJson);
        _localBookings = decoded.map((item) {
          return BookingModel.fromJson(item);
        }).toList();
        print('Loaded ${_localBookings.length} bookings from local storage');
      }
    } catch (e) {
      print('Error loading local bookings: $e');
    }
  }

  // Save bookings to local storage
  Future<void> _saveLocalBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = jsonEncode(_localBookings.map((booking) {
        if (booking is BookingModel) {
          return booking.toJson();
        } else {
          return BookingModel.fromEntity(booking).toJson();
        }
      }).toList());
      await prefs.setString('local_bookings', bookingsJson);
    } catch (e) {
      print('Error saving local bookings: $e');
    }
  }

  // Create a new booking
  Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      // Create a unique ID for the booking
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      bookingData['id'] = bookingId;
      
      // Ensure all required fields are present
      if (!bookingData.containsKey('requestDate')) {
        bookingData['requestDate'] = FieldValue.serverTimestamp();
      }
      
      if (!bookingData.containsKey('status')) {
        bookingData['status'] = 'pending';
      }

      // Create a booking entity for local cache
      final newBooking = BookingModel(
        id: bookingData['id'],
        skillId: bookingData['skillId'],
        skillTitle: bookingData['skillTitle'],
        providerId: bookingData['providerId'],
        providerName: bookingData['providerName'],
        clientId: bookingData['clientId'],
        clientName: bookingData['clientName'],
        bookingDate: bookingData['bookingDate'],
        requestDate: DateTime.now(),
        status: bookingData['status'],
        price: (bookingData['price'] ?? 0).toDouble(),
        notes: bookingData['notes'],
        location: bookingData['location'],
        isOnline: bookingData['isOnline'] ?? false,
      );

      // Always add to local cache first to ensure data is available
      _localBookings.insert(0, newBooking);
      print('Added booking to local cache: ${newBooking.skillTitle}');

      // Save to local storage
      await _saveLocalBookings();

      // Try to save to Firebase
      if (await _checkConnectivity()) {
        try {
          await _firestore.collection('bookings').doc(bookingId).set(
                bookingData is Map<String, dynamic>
                    ? bookingData
                    : BookingModel.fromEntity(newBooking).toJson(),
              );
          print('Booking saved to Firebase successfully');
        } catch (e) {
          print('Error saving booking to Firebase: $e');
          // Continue since we saved locally
        }
      }

      return true;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  // Get bookings for the current user (as client)
  Future<List<Booking>> getUserBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      if (!_isOfflineMode) {
        try {
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('clientId', isEqualTo: user.uid)
              .orderBy('requestDate', descending: true)
              .get();

          final bookings = bookingsSnapshot.docs.map((doc) {
            return BookingModel.fromJson(doc.data());
          }).toList();

          // Update local cache
          _localBookings = [...bookings, ..._localBookings.where((booking) => 
            booking.clientId == user.uid && 
            !bookings.any((b) => b.id == booking.id)
          )];
          await _saveLocalBookings();

          return bookings;
        } catch (e) {
          print('Error fetching bookings from Firestore: $e');
          // Fall back to local cache
        }
      }

      // Return from local cache
      return _localBookings.where((booking) => booking.clientId == user.uid).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  // Get bookings for the current user (as provider)
  Future<List<Booking>> getProviderBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      if (!_isOfflineMode) {
        try {
          final bookingsSnapshot = await _firestore
              .collection('bookings')
              .where('providerId', isEqualTo: user.uid)
              .orderBy('requestDate', descending: true)
              .get();

          final bookings = bookingsSnapshot.docs.map((doc) {
            return BookingModel.fromJson(doc.data());
          }).toList();

          // Update local cache
          _localBookings = [...bookings, ..._localBookings.where((booking) => 
            booking.providerId == user.uid && 
            !bookings.any((b) => b.id == booking.id)
          )];
          await _saveLocalBookings();

          return bookings;
        } catch (e) {
          print('Error fetching provider bookings from Firestore: $e');
          // Fall back to local cache
        }
      }

      // Return from local cache
      return _localBookings.where((booking) => booking.providerId == user.uid).toList();
    } catch (e) {
      print('Error getting provider bookings: $e');
      return [];
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      // Update in local cache first
      final bookingIndex = _localBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex >= 0) {
        final updatedBooking = _localBookings[bookingIndex].copyWith(status: status);
        _localBookings[bookingIndex] = updatedBooking;
        await _saveLocalBookings();
      }

      // Try to update in Firebase
      if (!_isOfflineMode) {
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': status,
          });
          print('Booking status updated in Firebase');
        } catch (e) {
          print('Error updating booking status in Firebase: $e');
          // Continue since we updated locally
        }
      }

      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      // Check local cache first
      final localBooking = _localBookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => BookingModel(
          id: '',
          skillId: '',
          skillTitle: '',
          providerId: '',
          providerName: '',
          clientId: '',
          clientName: '',
          bookingDate: DateTime.now(),
          requestDate: DateTime.now(),
          status: '',
          price: 0,
        ),
      );

      if (localBooking.id.isNotEmpty) {
        return localBooking;
      }

      // Try to fetch from Firebase
      if (!_isOfflineMode) {
        try {
          final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
          if (bookingDoc.exists) {
            return BookingModel.fromJson(bookingDoc.data()!);
          }
        } catch (e) {
          print('Error fetching booking from Firestore: $e');
        }
      }

      return null;
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }
}
