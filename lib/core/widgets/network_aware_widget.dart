import 'package:flutter/material.dart';
import 'package:skill_hub/core/services/connectivity_service.dart';
import 'package:skill_hub/core/theme/app_theme.dart';

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final Function? onRetry;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  NetworkAwareWidgetState createState() => NetworkAwareWidgetState();
}

class NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectivityStream.listen((status) {
      setState(() {
        _connectivityStatus = status;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    // Don't show loading indicator, just check connectivity in the background
    final status = await _connectivityService.checkConnectivity();

    if (mounted) {
      setState(() {
        _connectivityStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show offline screen if we're definitely offline
    // Don't interrupt the user experience with loading screens
    if (_connectivityStatus == ConnectivityStatus.offline) {
      return _buildOfflineScreen();
    }

    // Otherwise, show the app
    return widget.child;
  }

  Widget _buildOfflineScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 24),
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your internet connection and try again. The app will work in offline mode with limited functionality.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    _checkConnectivity();
                    if (widget.onRetry != null) {
                      widget.onRetry!();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Continue to app in offline mode
                    setState(() {
                      _connectivityStatus = ConnectivityStatus.online;
                    });
                  },
                  child: const Text('Continue in Offline Mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
