import 'package:flutter/material.dart';

class CityPickerDialog extends StatelessWidget {
  final String country;
  final String state;
  final Function(String) onCitySelected;

  const CityPickerDialog({
    Key? key,
    required this.country,
    required this.state,
    required this.onCitySelected,
  }) : super(key: key);

  // This is a simplified list. You should replace this with your actual city data
  List<String> getCitiesForState(String country, String state) {
    // This is just an example. You should implement a proper city database
    switch (state) {
      case 'Maharashtra':
        return [
          'Mumbai',
          'Pune',
          'Nagpur',
          'Thane',
          'Nashik',
          'Aurangabad',
          'Solapur',
          'Kolhapur',
          'Amravati',
          'Navi Mumbai'
        ];
      case 'Karnataka':
        return [
          'Bangalore',
          'Mysore',
          'Hubli',
          'Mangalore',
          'Belgaum',
          'Gulbarga',
          'Dharwad',
          'Davangere',
          'Bellary',
          'Shimoga'
        ];
      case 'California':
        return [
          'Los Angeles',
          'San Francisco',
          'San Diego',
          'San Jose',
          'Sacramento',
          'Oakland',
          'Fresno',
          'Long Beach',
          'Bakersfield',
          'Anaheim'
        ];
      case 'New York':
        return [
          'New York City',
          'Buffalo',
          'Rochester',
          'Yonkers',
          'Syracuse',
          'Albany',
          'New Rochelle',
          'Mount Vernon',
          'Schenectady',
          'Utica'
        ];
      // Add more states as needed
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = getCitiesForState(country, state);

    return AlertDialog(
      title: Text('Select City in $state'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: cities.map((city) {
            return ListTile(
              title: Text(city),
              onTap: () {
                onCitySelected(city);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
