import 'package:flutter/material.dart';

class AddressUtils {
  // List of Indian cities for autocomplete suggestions
  static final List<String> cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Ranchi',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan-Dombivli',
    'Vasai-Virar',
    'Varanasi',
    'Srinagar',
    'Aurangabad',
    'Dhanbad',
    'Amritsar',
    'Navi Mumbai',
    'Allahabad',
    'Howrah',
    'Gwalior',
    'Jabalpur',
    'Coimbatore',
    'Vijayawada'
  ];

  // List of Indian states
  static final List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal'
  ];

  // Get address suggestions based on input text
  static List<String> getSuggestions(String query) {
    if (query.isEmpty) {
      return [];
    }

    // Combine cities and states for suggestions
    final allLocations = [...cities, ...states, 'India'];

    // Filter suggestions based on query
    return allLocations
        .where(
            (location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Format the address string
  static String formatAddress(String city, String state) {
    if (city.isEmpty && state.isEmpty) {
      return '';
    } else if (city.isEmpty) {
      return '$state, India';
    } else if (state.isEmpty) {
      return '$city, India';
    } else {
      return '$city, $state, India';
    }
  }
}
