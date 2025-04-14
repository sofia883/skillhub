import 'package:flutter/material.dart';

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
    // Try to parse the initial location if it's in the format "City, State, Country"
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

  // Sample data for countries
  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'China',
    'India',
    'Brazil',
    'Mexico',
    'South Africa',
  ];

  // Sample data for states based on country
  Map<String, List<String>> _states = {
    'United States': ['California', 'New York', 'Texas', 'Florida', 'Illinois'],
    'Canada': ['Ontario', 'Quebec', 'British Columbia', 'Alberta', 'Manitoba'],
    'United Kingdom': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    'Australia': [
      'New South Wales',
      'Victoria',
      'Queensland',
      'Western Australia'
    ],
    'India': ['Maharashtra', 'Delhi', 'Tamil Nadu', 'Karnataka', 'Gujarat'],
  };

  // Sample data for cities based on state
  Map<String, List<String>> _cities = {
    'California': ['Los Angeles', 'San Francisco', 'San Diego', 'San Jose'],
    'New York': ['New York City', 'Buffalo', 'Rochester', 'Syracuse'],
    'Texas': ['Houston', 'Austin', 'Dallas', 'San Antonio'],
    'Florida': ['Miami', 'Orlando', 'Tampa', 'Jacksonville'],
    'Ontario': ['Toronto', 'Ottawa', 'Mississauga', 'Hamilton'],
    'Quebec': ['Montreal', 'Quebec City', 'Laval', 'Gatineau'],
    'England': ['London', 'Manchester', 'Birmingham', 'Liverpool'],
    'Scotland': ['Edinburgh', 'Glasgow', 'Aberdeen', 'Dundee'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane'],
    'Delhi': ['New Delhi', 'Noida', 'Gurgaon', 'Faridabad'],
  };

  // Get dropdown items for countries
  List<DropdownMenuItem<String>> _getCountryItems() {
    return _countries.map((country) {
      return DropdownMenuItem<String>(
        value: country,
        child: Text(country),
      );
    }).toList();
  }

  // Get dropdown items for states based on selected country
  List<DropdownMenuItem<String>> _getStateItems() {
    if (_selectedCountry == null || !_states.containsKey(_selectedCountry)) {
      return [];
    }

    return _states[_selectedCountry]!.map((state) {
      return DropdownMenuItem<String>(
        value: state,
        child: Text(state),
      );
    }).toList();
  }

  // Get dropdown items for cities based on selected state
  List<DropdownMenuItem<String>> _getCityItems() {
    if (_selectedState == null || !_cities.containsKey(_selectedState)) {
      return [];
    }

    return _cities[_selectedState]!.map((city) {
      return DropdownMenuItem<String>(
        value: city,
        child: Text(city),
      );
    }).toList();
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

        // Country, State, City Picker
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCountry,
                      hint: const Text('Select Country'),
                      items: _getCountryItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                          _selectedState =
                              null; // Reset state when country changes
                          _selectedCity =
                              null; // Reset city when country changes
                        });
                        _updateLocationString();
                      },
                    ),
                    const SizedBox(height: 16),

                    // State dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'State/Province',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedState,
                      hint: const Text('Select State/Province'),
                      items: _getStateItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedCity = null; // Reset city when state changes
                        });
                        _updateLocationString();
                      },
                    ),
                    const SizedBox(height: 16),

                    // City dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCity,
                      hint: const Text('Select City'),
                      items: _getCityItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                        _updateLocationString();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Current location info
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
