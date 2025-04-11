import 'package:flutter/material.dart';

class AddressSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddressSelected;
  final Map<String, dynamic>? initialAddress;

  const AddressSelector({
    Key? key,
    required this.onAddressSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  AddressSelectorState createState() => AddressSelectorState();
}

class AddressSelectorState extends State<AddressSelector> {
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  // Predefined lists
  final List<String> _countries = ['India', 'United States', 'Canada', 'United Kingdom', 'Australia'];
  
  // States by country
  final Map<String, List<String>> _statesByCountry = {
    'India': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
      'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry', 'Chandigarh'
    ],
    'United States': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
      'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
      'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan',
      'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
      'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
      'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia',
      'Wisconsin', 'Wyoming'
    ],
    // Add more countries and states as needed
  };
  
  // Cities by state (simplified for demo)
  final Map<String, List<String>> _citiesByState = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
    // Add more states and cities as needed
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize with provided address if available
    if (widget.initialAddress != null) {
      _selectedCountry = widget.initialAddress!['country'];
      _selectedState = widget.initialAddress!['state'];
      _selectedCity = widget.initialAddress!['city'];
      _streetController.text = widget.initialAddress!['street'] ?? '';
      _houseNumberController.text = widget.initialAddress!['houseNumber'] ?? '';
      _zipCodeController.text = widget.initialAddress!['zipCode'] ?? '';
    } else {
      // Default to India
      _selectedCountry = 'India';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  // Update the address and notify parent
  void _updateAddress() {
    final address = {
      'country': _selectedCountry,
      'state': _selectedState,
      'city': _selectedCity,
      'street': _streetController.text,
      'houseNumber': _houseNumberController.text,
      'zipCode': _zipCodeController.text,
      'formatted': _getFormattedAddress(),
    };
    
    widget.onAddressSelected(address);
  }

  // Get a formatted address string
  String _getFormattedAddress() {
    final parts = <String>[];
    
    if (_houseNumberController.text.isNotEmpty) {
      parts.add(_houseNumberController.text);
    }
    
    if (_streetController.text.isNotEmpty) {
      parts.add(_streetController.text);
    }
    
    if (_selectedCity != null) {
      parts.add(_selectedCity!);
    }
    
    if (_selectedState != null) {
      parts.add(_selectedState!);
    }
    
    if (_zipCodeController.text.isNotEmpty) {
      parts.add(_zipCodeController.text);
    }
    
    if (_selectedCountry != null) {
      parts.add(_selectedCountry!);
    }
    
    return parts.join(', ');
  }

  // Filter list based on search query
  List<String> _filterList(List<String> list, String query) {
    if (query.isEmpty) {
      return list;
    }
    
    final lowerCaseQuery = query.toLowerCase();
    return list.where((item) => 
      item.toLowerCase().contains(lowerCaseQuery)
    ).toList();
  }

  // Show search dialog for selection
  Future<void> _showSearchDialog({
    required String title,
    required List<String> items,
    required Function(String) onSelected,
  }) async {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredItems = List.from(items);
    
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredItems = _filterList(items, value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // List of items
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredItems[index]),
                            onTap: () {
                              onSelected(filteredItems[index]);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selection
        InkWell(
          onTap: () async {
            await _showSearchDialog(
              title: 'Select Country',
              items: _countries,
              onSelected: (country) {
                setState(() {
                  _selectedCountry = country;
                  _selectedState = null;
                  _selectedCity = null;
                });
                _updateAddress();
              },
            );
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(_selectedCountry ?? 'Select Country'),
          ),
        ),
        const SizedBox(height: 16),
        
        // State selection
        InkWell(
          onTap: _selectedCountry == null
              ? null
              : () async {
                  final states = _statesByCountry[_selectedCountry] ?? [];
                  if (states.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No states available for selected country')),
                    );
                    return;
                  }
                  
                  await _showSearchDialog(
                    title: 'Select State',
                    items: states,
                    onSelected: (state) {
                      setState(() {
                        _selectedState = state;
                        _selectedCity = null;
                      });
                      _updateAddress();
                    },
                  );
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'State/Province',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              enabled: _selectedCountry != null,
            ),
            child: Text(_selectedState ?? 'Select State'),
          ),
        ),
        const SizedBox(height: 16),
        
        // City selection
        InkWell(
          onTap: _selectedState == null
              ? null
              : () async {
                  final cities = _citiesByState[_selectedState] ?? [];
                  if (cities.isEmpty) {
                    // Allow manual entry if no predefined cities
                    final TextEditingController cityController = TextEditingController();
                    if (_selectedCity != null) {
                      cityController.text = _selectedCity!;
                    }
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Enter City'),
                        content: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            hintText: 'City name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (cityController.text.isNotEmpty) {
                                setState(() {
                                  _selectedCity = cityController.text;
                                });
                                _updateAddress();
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  
                  await _showSearchDialog(
                    title: 'Select City',
                    items: cities,
                    onSelected: (city) {
                      setState(() {
                        _selectedCity = city;
                      });
                      _updateAddress();
                    },
                  );
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'City',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              enabled: _selectedState != null,
            ),
            child: Text(_selectedCity ?? 'Select City'),
          ),
        ),
        const SizedBox(height: 16),
        
        // Street
        TextField(
          controller: _streetController,
          decoration: const InputDecoration(
            labelText: 'Street',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateAddress(),
        ),
        const SizedBox(height: 16),
        
        // House number and ZIP code in a row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _houseNumberController,
                decoration: const InputDecoration(
                  labelText: 'House/Building Number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateAddress(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'ZIP/Postal Code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateAddress(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
