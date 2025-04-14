import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

enum PricingModel {
  fixed('Fixed Price'),
  hourly('Per Hour'),
  daily('Per Day'),
  fullSet('Full Set'),
  manual('Enter Custom Price'),
  contact('Contact for Pricing');

  final String label;
  const PricingModel(this.label);
}

class PriceInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String, String) onCurrencyAndTypeChanged;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const PriceInput({
    Key? key,
    required this.controller,
    required this.onCurrencyAndTypeChanged,
    this.validator,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<PriceInput> createState() => _PriceInputState();
}

class _PriceInputState extends State<PriceInput> {
  String _selectedCurrency = '₹';
  String _selectedType = 'Fixed';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType != 'Contact for Pricing') ...[
          Row(
            children: [
              // Currency dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  underline: const SizedBox(),
                  items: ['₹', '\$', '€', '£'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                      widget.onCurrencyAndTypeChanged(
                          _selectedCurrency, _selectedType);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Price input field
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'Enter price',
                  ),
                  validator: widget.validator,
                  autovalidateMode: widget.autovalidateMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Price type selection
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Fixed'),
              selected: _selectedType == 'Fixed',
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedType = 'Fixed';
                  });
                  widget.onCurrencyAndTypeChanged(
                      _selectedCurrency, _selectedType);
                }
              },
            ),
            ChoiceChip(
              label: const Text('Hourly'),
              selected: _selectedType == 'Hourly',
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedType = 'Hourly';
                  });
                  widget.onCurrencyAndTypeChanged(
                      _selectedCurrency, _selectedType);
                }
              },
            ),
            ChoiceChip(
              label: const Text('Contact for Pricing'),
              selected: _selectedType == 'Contact for Pricing',
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedType = 'Contact for Pricing';
                    widget.controller.clear();
                  });
                  widget.onCurrencyAndTypeChanged(
                      _selectedCurrency, _selectedType);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
