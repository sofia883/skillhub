import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Connectivity instance
  final Connectivity _connectivity = Connectivity();

  // Stream controller for connectivity status
  final _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();

  // Stream getter
  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;

  // Current status
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  ConnectivityStatus get currentStatus => _currentStatus;

  // Initialize the service
  void initialize() {
    // Check initial connectivity
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  // Check current connectivity
  Future<ConnectivityStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }

  // Internal method to check connectivity
  Future<ConnectivityStatus> _checkConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _currentStatus;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _currentStatus = ConnectivityStatus.offline;
      _connectivityController.add(_currentStatus);
      return _currentStatus;
    }
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    ConnectivityStatus status;

    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        status = ConnectivityStatus.online;
        break;
      case ConnectivityResult.none:
        status = ConnectivityStatus.offline;
        break;
      default:
        status = ConnectivityStatus.unknown;
        break;
    }

    // Only notify if status changed
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectivityController.add(status);
    }
  }

  // Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}

// Enum for connectivity status
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}
