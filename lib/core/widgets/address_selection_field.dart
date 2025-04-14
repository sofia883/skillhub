import 'package:flutter/material.dart';
import 'package:skill_hub/core/services/location_service.dart';

class AddressSelectionField extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController countryController;
  final TextEditingController stateController;
  final TextEditingController cityController;
  final String? Function(String?)? validator;
  final String label;

  const AddressSelectionField({
    Key? key,
    required this.addressController,
    required this.countryController,
    required this.stateController,
    required this.cityController,
    this.validator,
    required this.label,
  }) : super(key: key);

  @override
  State<AddressSelectionField> createState() => _AddressSelectionFieldState();
}

class _AddressSelectionFieldState extends State<AddressSelectionField> {
  final _locationService = LocationService();
  bool _isLoading = false;
  final _searchController = TextEditingController();

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        widget.addressController.text = address['fullAddress'] ?? '';
        widget.countryController.text = address['country'] ?? '';
        widget.stateController.text = address['state'] ?? '';
        widget.cityController.text = address['city'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchLocation() async {
    if (_isLoading) return;

    final String? searchQuery = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Address'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter address to search',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _searchController.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (searchQuery == null || searchQuery.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final result = await _locationService.searchPlace(searchQuery);
      if (!mounted) return;

      setState(() {
        widget.addressController.text = result['fullAddress'] ?? '';
        widget.countryController.text = result['country'] ?? '';
        widget.stateController.text = result['state'] ?? '';
        widget.cityController.text = result['city'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.addressController,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Use current location',
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchLocation,
                        tooltip: 'Search location',
                      ),
                    ],
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.countryController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: widget.stateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.cityController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
