import 'package:flutter/material.dart';

class PhoneInput extends StatefulWidget {
  final String initialValue;
  final Function(String) onPhoneChanged;
  final String? Function(String?)? validator;

  const PhoneInput({
    super.key,
    required this.initialValue,
    required this.onPhoneChanged,
    this.validator,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  late TextEditingController _phoneController;
  final List<String> _countryCodes = [
    '+1', // USA/Canada
    '+44', // UK
    '+91', // India
    '+61', // Australia
    '+49', // Germany
    '+33', // France
    '+86', // China
    '+81', // Japan
    '+7', // Russia
    '+55', // Brazil
    '+52', // Mexico
    '+27', // South Africa
  ];
  String _selectedCountryCode = '+1'; // Default to US

  @override
  void initState() {
    super.initState();
    _parseInitialValue();
  }

  void _parseInitialValue() {
    // Try to parse the initial value if it has a country code
    if (widget.initialValue.startsWith('+')) {
      // This is a rough estimation, as proper parsing would require a more complex approach
      for (final code in _countryCodes) {
        if (widget.initialValue.startsWith(code)) {
          _selectedCountryCode = code;
          _phoneController = TextEditingController(
            text: widget.initialValue.substring(code.length).trim(),
          );
          return;
        }
      }
      // If no matching country code found
      _phoneController = TextEditingController(text: widget.initialValue);
    } else {
      _phoneController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _updatePhoneNumber() {
    final completeNumber =
        '$_selectedCountryCode ${_phoneController.text.trim()}';
    widget.onPhoneChanged(completeNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code dropdown
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                underline: const SizedBox(), // Remove the default underline
                items: _countryCodes.map((code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(code),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountryCode = value;
                    });
                    _updatePhoneNumber();
                  }
                },
              ),
            ),

            // Phone number input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: 'Phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  _updatePhoneNumber();
                },
                validator: widget.validator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Include country code for international calls',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
