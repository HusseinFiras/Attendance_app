import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _activeController;
  bool _isDisposing = false;

  // Getter for active controller
  CameraController? get activeController => _activeController;

  // Register active camera controller
  void registerCamera(CameraController controller) {
    if (_activeController != controller) {
      cleanupCamera();
      _activeController = controller;
    }
  }

  // Cleanup camera resources
  Future<void> cleanupCamera() async {
    if (_isDisposing) return;
    _isDisposing = true;

    try {
      final controller = _activeController;
      if (controller != null) {
        if (controller.value.isInitialized) {
          if (controller.value.isStreamingImages) {
            await controller.stopImageStream();
          }
          await controller.dispose();
        }
        _activeController = null;
      }
    } catch (e) {
      debugPrint('Error cleaning up camera: $e');
    } finally {
      _isDisposing = false;
    }
  }
} 