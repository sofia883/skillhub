import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

class EnhancedLocationSelector extends StatefulWidget {
  final String initialLocation;
  final Function(String) onLocationSelected;

  const EnhancedLocationSelector({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<EnhancedLocationSelector> createState() =>
      _EnhancedLocationSelectorState();
}

class _EnhancedLocationSelectorState extends State<EnhancedLocationSelector> {
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _parseInitialLocation();
  }

  void _parseInitialLocation() {
    final parts =
        widget.initialLocation.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      setState(() {
        _selectedCity = parts[0];
        _selectedState = parts[1];
        _selectedCountry = parts[2];
      });
    } else if (parts.length == 2) {
      setState(() {
        _selectedCity = parts[0];
        _selectedState = parts[1];
      });
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      setState(() {
        _selectedCity = parts[0];
      });
    }
  }

  void _updateLocationString() {
    String location = '';
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      location = _selectedCity!;
    }
    if (_selectedState != null && _selectedState!.isNotEmpty) {
      location =
          location.isEmpty ? _selectedState! : '$location, $_selectedState';
    }
    if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
      location =
          location.isEmpty ? _selectedCountry! : '$location, $_selectedCountry';
    }
    widget.onLocationSelected(location);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SelectState(
                  onCountryChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedState = null;
                      _selectedCity = null;
                    });
                    _updateLocationString();
                  },
                  onStateChanged: (value) {
                    setState(() {
                      _selectedState = value;
                      _selectedCity = null;
                    });
                    _updateLocationString();
                  },
                  onCityChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                    _updateLocationString();
                  },
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedCountry != null ||
                    _selectedState != null ||
                    _selectedCity != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Location:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedCity ?? ""}${_selectedState != null ? ", $_selectedState" : ""}${_selectedCountry != null ? ", $_selectedCountry" : ""}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
