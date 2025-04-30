import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pipe_communicator.dart';
import 'python_backend_manager.dart';
import 'qr_communicator.dart';

class QRScanResult {
  final String data;
  final String type;
  final bool isValid;
  final List<List<int>> points;
  
  QRScanResult({
    required this.data,
    required this.type,
    required this.isValid,
    required this.points,
  });
  
  factory QRScanResult.fromJson(Map<String, dynamic> json) {
    return QRScanResult(
      data: json['data'],
      type: json['type'],
      isValid: json['valid'] ?? false,
      points: (json['points'] as List?)
          ?.map((e) => (e as List).map((p) => p as int).toList())
          ?.toList() ?? [],
    );
  }
}

class QRScanResponse {
  final List<QRScanResult> results;
  final Uint8List? debugImage;
  final double processingTimeMs;
  final double averageTimeMs;
  final int totalFrames;
  final int successfulDetections;
  
  QRScanResponse({
    required this.results,
    this.debugImage,
    required this.processingTimeMs,
    required this.averageTimeMs,
    required this.totalFrames,
    required this.successfulDetections,
  });
  
  factory QRScanResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List?)
        ?.map((e) => QRScanResult.fromJson(e))
        ?.toList() ?? [];
        
    Uint8List? debugImage;
    if (json['debug_image'] != null) {
      debugImage = base64Decode(json['debug_image']);
    }
    
    return QRScanResponse(
      results: results,
      debugImage: debugImage,
      processingTimeMs: json['processing_time_ms'] ?? 0.0,
      averageTimeMs: json['average_time_ms'] ?? 0.0,
      totalFrames: json['total_frames'] ?? 0,
      successfulDetections: json['successful_detections'] ?? 0,
    );
  }
}

class PythonQRScanner {
  final Function(String) onQRDetected;
  final PythonBackendManager _backendManager;
  final QRCommunicator _communicator;
  
  bool _isBackendRunning = false;
  bool _isPipeAvailable = false;
  QRResponse? lastResponse;
  DateTime? _lastFrameTime;
  static const Duration _minFrameInterval = Duration(milliseconds: 100);

  PythonQRScanner({
    required this.onQRDetected,
  }) : _backendManager = PythonBackendManager(),
       _communicator = QRCommunicator();

  PythonBackendManager get backendManager => _backendManager;

  Future<bool> initialize() async {
    try {
      // Start the backend
      _isBackendRunning = await _backendManager.startBackend();
      if (!_isBackendRunning) {
        debugPrint('Failed to start backend process');
        return false;
      }

      // Wait for backend to initialize
      await Future.delayed(const Duration(seconds: 2));

      // Verify pipe is available
      _isPipeAvailable = await _communicator.isPipeAvailable();
      if (!_isPipeAvailable) {
        debugPrint('Pipe server not available');
        return false;
      }

      // Test communication
      final testResult = await testConnection();
      if (testResult == null) {
        debugPrint('Failed to establish communication with backend');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error during QR scanner initialization: $e');
      return false;
    }
  }

  Future<QRResponse?> testConnection() async {
    try {
      final response = await _communicator.sendTestMessage();
      return response;
    } catch (e) {
      debugPrint('Test connection failed: $e');
      return null;
    }
  }

  Future<void> processFrame(CameraImage frame) async {
    // Skip if backend not ready
    if (!_isBackendRunning || !_isPipeAvailable) {
      return;
    }

    // Rate limiting
    final now = DateTime.now();
    if (_lastFrameTime != null && 
        now.difference(_lastFrameTime!) < _minFrameInterval) {
      return;
    }
    _lastFrameTime = now;

    try {
      final response = await _communicator.sendFrame(frame);
      lastResponse = response;

      if (response != null && response.results.isNotEmpty) {
        final qrData = response.results.first.data;
        onQRDetected(qrData);
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
      // Attempt to recover if pipe error
      if (e.toString().contains('pipe')) {
        _isPipeAvailable = false;
        await initialize();
      }
    }
  }

  void dispose() {
    _backendManager.stopBackend();
    _isBackendRunning = false;
    _isPipeAvailable = false;
  }
} 