import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String? initialCountryCode;
  final ValueChanged<String>? onCountryCodeChanged;

  const PhoneNumberField({
    Key? key,
    required this.controller,
    this.validator,
    required this.label,
    this.initialCountryCode,
    this.onCountryCodeChanged,
  }) : super(key: key);

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  String _countryCode = '+1'; // Default to US

  @override
  void initState() {
    super.initState();
    if (widget.initialCountryCode != null) {
      _countryCode = widget.initialCountryCode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: IconButton(
          icon: Text(_countryCode),
          onPressed: () {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (Country country) {
                setState(() {
                  _countryCode = '+${country.phoneCode}';
                });
                if (widget.onCountryCodeChanged != null) {
                  widget.onCountryCodeChanged!('+${country.phoneCode}');
                }
              },
              favorite: const ['US', 'GB', 'IN'],
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
