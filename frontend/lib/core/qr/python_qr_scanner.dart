import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pipe_communicator.dart';

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
  final void Function(String) onQRDetected;
  final PipeCommunicator _communicator = PipeCommunicator();
  
  bool _isProcessing = false;
  String? _lastDetectedData;
  DateTime? _lastProcessTime;
  
  // Debug information
  QRScanResponse? _lastResponse;
  QRScanResponse? get lastResponse => _lastResponse;
  
  PythonQRScanner({required this.onQRDetected});
  
  Future<QRScanResponse?> testConnection() async {
    try {
      // Create a test request with a small black image
      final testImage = Uint8List(100 * 100 * 4); // 100x100 black image in BGRA format
      final base64Image = base64Encode(testImage);
      
      final request = json.encode({
        'image': base64Image,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      final responseJson = await _communicator.sendMessage(request);
      if (responseJson == null) {
        return null;
      }
      
      final Map<String, dynamic> responseMap = json.decode(responseJson);
      if (responseMap.containsKey('error')) {
        debugPrint('Test connection error: ${responseMap['error']}');
        return null;
      }
      
      return QRScanResponse.fromJson(responseMap);
    } catch (e) {
      debugPrint('Test connection failed: $e');
      return null;
    }
  }
  
  Future<void> processFrame(CameraImage frame) async {
    // Skip if already processing or not enough time passed
    if (_isProcessing) return;
    
    final now = DateTime.now();
    if (_lastProcessTime != null) {
      final elapsed = now.difference(_lastProcessTime!);
      if (elapsed.inMilliseconds < 100) {  // Max 10 FPS for processing
        return;
      }
    }
    
    _isProcessing = true;
    _lastProcessTime = now;
    
    try {
      // Convert frame to base64
      final bytes = _convertFrameToBytes(frame);
      final base64Image = base64Encode(bytes);
      
      // Create request JSON
      final request = json.encode({
        'image': base64Image,
        'timestamp': now.millisecondsSinceEpoch,
      });
      
      // Send to Python backend
      final responseJson = await _communicator.sendMessage(request);
      if (responseJson == null) {
        return;
      }
      
      // Parse response
      final Map<String, dynamic> responseMap = json.decode(responseJson);
      if (responseMap.containsKey('error')) {
        debugPrint('QR processing error: ${responseMap['error']}');
        return;
      }
      
      // Create response object
      final response = QRScanResponse.fromJson(responseMap);
      _lastResponse = response;
      
      // Process QR results
      if (response.results.isNotEmpty) {
        // Get first valid QR code
        final validResults = response.results.where((r) => r.isValid).toList();
        if (validResults.isNotEmpty) {
          final qrData = validResults.first.data;
          
          // Notify if new QR code detected
          if (qrData != _lastDetectedData) {
            _lastDetectedData = qrData;
            onQRDetected(qrData);
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  Uint8List _convertFrameToBytes(CameraImage image) {
    // Handle BGRA format (Windows)
    if (image.format.group == ImageFormatGroup.bgra8888) {
      // For Windows, we get direct access to the pixel data
      return image.planes[0].bytes;
    }
    
    // Fallback for other formats (unlikely on Windows)
    throw UnsupportedError('Unsupported image format: ${image.format.group}');
  }

  void dispose() {
    _isProcessing = false;
    _lastDetectedData = null;
    _lastProcessTime = null;
    _lastResponse = null;
  }
} 