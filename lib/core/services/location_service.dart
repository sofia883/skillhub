import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Get current location
  Future<Position> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Get address from coordinates
  Future<Map<String, String>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('No address found for these coordinates');
      }

      Placemark place = placemarks[0];

      // Handle nullable strings and create address parts
      final List<String> addressParts = [
        if (place.street?.isNotEmpty ?? false) place.street!,
        if (place.subLocality?.isNotEmpty ?? false) place.subLocality!,
        if (place.locality?.isNotEmpty ?? false) place.locality!,
        if (place.administrativeArea?.isNotEmpty ?? false)
          place.administrativeArea!,
        if (place.country?.isNotEmpty ?? false) place.country!,
      ];

      return {
        'street': place.street ?? '',
        'subLocality': place.subLocality ?? '',
        'city': place.locality ?? '',
        'state': place.administrativeArea ?? '',
        'country': place.country ?? '',
        'postalCode': place.postalCode ?? '',
        'fullAddress': addressParts.join(', '),
      };
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  // Search for an address and return coordinates and address details
  Future<Map<String, dynamic>> searchPlace(String query) async {
    try {
      if (query.isEmpty) {
        return {};
      }

      // Get coordinates from address string
      List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        return {};
      }

      Location location = locations.first;

      // Get detailed address from coordinates
      Map<String, String> address = await getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      return {
        ...address,
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (e) {
      throw Exception('Failed to search place: $e');
    }
  }
}
