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
  final Function(String currency, String priceType) onCurrencyAndTypeChanged;

  const PriceInput({
    super.key,
    required this.controller,
    required this.onCurrencyAndTypeChanged,
  });

  @override
  State<PriceInput> createState() => _PriceInputState();
}

class _PriceInputState extends State<PriceInput> {
  String _selectedCurrency = '₹';
  String _selectedPriceType = 'Fixed Price';
  bool _showPriceInput = true;

  final List<String> _currencies = ['₹', '\$'];
  final List<String> _priceTypes = [
    'Fixed Price',
    'Per Hour',
    'Per Day',
    'Per Session',
    'Per Project',
    'Enter Custom Price',
    'Contact for Pricing'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Currency and Amount Row
              if (_showPriceInput) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        underline: const SizedBox(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _currencies.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(
                              currency,
                              style: theme.textTheme.titleMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                            widget.onCurrencyAndTypeChanged(
                                _selectedCurrency, _selectedPriceType);
                          }
                        },
                      ),
                    ),
                    // Amount Input
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Enter amount',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: Colors.grey[300]),
              ],
              // Price Type Dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedPriceType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _priceTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPriceType = newValue;
                        _showPriceInput = newValue != 'Contact for Pricing';
                        if (!_showPriceInput) {
                          widget.controller.clear();
                        }
                      });
                      widget.onCurrencyAndTypeChanged(
                          _selectedCurrency, _selectedPriceType);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
