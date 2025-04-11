import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityStatusIndicator extends StatefulWidget {
  const ConnectivityStatusIndicator({super.key});

  @override
  State<ConnectivityStatusIndicator> createState() => _ConnectivityStatusIndicatorState();
}

class _ConnectivityStatusIndicatorState extends State<ConnectivityStatusIndicator> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectivityStream.listen((status) {
      if (mounted) {
        setState(() {
          _connectivityStatus = status;
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final status = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _connectivityStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're online or unknown, don't show anything
    if (_connectivityStatus == ConnectivityStatus.online || 
        _connectivityStatus == ConnectivityStatus.unknown) {
      return const SizedBox.shrink();
    }

    // If we're offline, show a banner
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.red.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'No Internet Connection',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _checkConnectivity,
            child: Text(
              'Retry',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
