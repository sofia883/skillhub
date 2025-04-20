import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _selectedCountry = widget.initialAddress!['country'];
      _selectedState = widget.initialAddress!['state'];
      _selectedCity = widget.initialAddress!['city'];
      _streetController.text = widget.initialAddress!['street'] ?? '';
      _houseNumberController.text = widget.initialAddress!['houseNumber'] ?? '';
      _zipCodeController.text = widget.initialAddress!['zipCode'] ?? '';
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectState(
          onCountryChanged: (value) {
            setState(() {
              _selectedCountry = value;
              _selectedState = null;
              _selectedCity = null;
            });
            _updateAddress();
          },
          onStateChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null;
            });
            _updateAddress();
          },
          onCityChanged: (value) {
            setState(() {
              _selectedCity = value;
            });
            _updateAddress();
          },
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
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

        // House Number
        TextField(
          controller: _houseNumberController,
          decoration: const InputDecoration(
            labelText: 'House/Building Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateAddress(),
        ),
        const SizedBox(height: 16),

        // ZIP Code
        TextField(
          controller: _zipCodeController,
          decoration: const InputDecoration(
            labelText: 'ZIP Code',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateAddress(),
        ),
        const SizedBox(height: 16),

        // Selected Address Preview
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
                  'Selected Address:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedAddress(),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
