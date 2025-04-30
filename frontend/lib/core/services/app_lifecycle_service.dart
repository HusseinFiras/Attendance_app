import 'package:flutter/material.dart';
import 'camera_service.dart';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final CameraService _cameraService = CameraService();
  bool _isRegistered = false;

  void initialize() {
    if (!_isRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isRegistered = true;
    }
  }

  void dispose() {
    if (_isRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isRegistered = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _cameraService.cleanupCamera();
        break;
      case AppLifecycleState.resumed:
        // Handle resume if needed
        break;
      default:
        break;
    }
  }
} 