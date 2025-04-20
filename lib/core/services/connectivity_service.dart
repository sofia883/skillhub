import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _lastStatus = ConnectivityStatus.unknown;
  Timer? _retryTimer;
  bool _isInitialized = false;

  Stream<ConnectivityStatus> get connectivityStream => _controller.stream;
  ConnectivityStatus get lastStatus => _lastStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load last known state
    final prefs = await SharedPreferences.getInstance();
    final lastStatusString = prefs.getString('last_connectivity_status');
    if (lastStatusString != null) {
      _lastStatus = ConnectivityStatus.values.firstWhere(
        (e) => e.toString() == lastStatusString,
        orElse: () => ConnectivityStatus.unknown,
      );
    }

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) async {
      final status = await _checkActualConnection(result);
      await _updateConnectionStatus(status);
    });

    // Initial check
    final initResult = await _connectivity.checkConnectivity();
    final status = await _checkActualConnection(initResult);
    await _updateConnectionStatus(status);
  }

  Future<ConnectivityStatus> _checkActualConnection(
      ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      return ConnectivityStatus.offline;
    }

    try {
      // Try to actually connect to something
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return ConnectivityStatus.online;
      }
    } catch (_) {
      return ConnectivityStatus.offline;
    }

    return ConnectivityStatus.offline;
  }

  Future<void> _updateConnectionStatus(ConnectivityStatus status) async {
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);

      // Save the new status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connectivity_status', status.toString());

      // Handle offline state
      if (status == ConnectivityStatus.offline) {
        _startRetryTimer();
      } else {
        _cancelRetryTimer();
      }
    }
  }

  void _startRetryTimer() {
    _cancelRetryTimer();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final result = await _connectivity.checkConnectivity();
      final status = await _checkActualConnection(result);
      await _updateConnectionStatus(status);
    });
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final status = await _checkActualConnection(result);
    await _updateConnectionStatus(status);
    return status;
  }

  void dispose() {
    _cancelRetryTimer();
    _controller.close();
  }
}
