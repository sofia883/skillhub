import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

class EnhancedCSCPicker extends StatefulWidget {
  final Function(String) onCountryChanged;
  final Function(String) onStateChanged;
  final Function(String) onCityChanged;
  final TextStyle? style;
  final String? selectedCountry;
  final String? selectedState;
  final String? selectedCity;

  const EnhancedCSCPicker({
    Key? key,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.style,
    this.selectedCountry,
    this.selectedState,
    this.selectedCity,
  }) : super(key: key);

  @override
  State<EnhancedCSCPicker> createState() => _EnhancedCSCPickerState();
}

class _EnhancedCSCPickerState extends State<EnhancedCSCPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectState(
          onCountryChanged: (value) {
            widget.onCountryChanged(value);
          },
          onStateChanged: (value) {
            if (value.isEmpty || value == "Choose State") {
              widget.onStateChanged("No states available for this country");
              return;
            }
            widget.onStateChanged(value);
          },
          onCityChanged: (value) {
            if (value.isEmpty || value == "Choose City") {
              widget.onCityChanged("No cities available for this state");
              return;
            }
            widget.onCityChanged(value);
          },
          style: widget.style ??
              const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
        ),

        // Selected location display
        if (widget.selectedCountry != null ||
            widget.selectedState != null ||
            widget.selectedCity != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              [
                if (widget.selectedCountry != null &&
                    widget.selectedCountry!.isNotEmpty &&
                    !widget.selectedCountry!.startsWith('No'))
                  widget.selectedCountry,
                if (widget.selectedState != null &&
                    widget.selectedState!.isNotEmpty &&
                    !widget.selectedState!.startsWith('No'))
                  widget.selectedState,
                if (widget.selectedCity != null &&
                    widget.selectedCity!.isNotEmpty &&
                    !widget.selectedCity!.startsWith('No'))
                  widget.selectedCity,
              ].where((e) => e != null).join(', '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
