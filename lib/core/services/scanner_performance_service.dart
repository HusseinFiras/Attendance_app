import 'package:flutter/material.dart';
import '../config/qr_scanner_config.dart';

class ScannerPerformanceService {
  int _totalFrames = 0;
  int _processedFrames = 0;
  int _droppedFrames = 0;
  int _successfulScans = 0;
  DateTime? _lastFrameTime;
  List<Duration> _processingTimes = [];
  
  void recordFrameProcessed(Duration processingTime) {
    _totalFrames++;
    _processedFrames++;
    _processingTimes.add(processingTime);
    
    if (processingTime > QRScannerConfig.maxProcessingTime) {
      _droppedFrames++;
    }

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameInterval = now.difference(_lastFrameTime!);
      if (frameInterval > QRScannerConfig.frameDropThreshold) {
        _droppedFrames++;
      }
    }
    _lastFrameTime = now;

    if (QRScannerConfig.enablePerformanceLogging && 
        _totalFrames % QRScannerConfig.performanceLogInterval == 0) {
      _logPerformanceMetrics();
    }
  }

  void recordSuccessfulScan() {
    _successfulScans++;
  }

  void reset() {
    _totalFrames = 0;
    _processedFrames = 0;
    _droppedFrames = 0;
    _successfulScans = 0;
    _lastFrameTime = null;
    _processingTimes.clear();
  }

  double get averageProcessingTime {
    if (_processingTimes.isEmpty) return 0;
    final total = _processingTimes.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );
    return total.inMicroseconds / _processingTimes.length / 1000; // Convert to ms
  }

  double get frameRate {
    if (_lastFrameTime == null || _totalFrames < 2) return 0;
    final duration = DateTime.now().difference(_lastFrameTime!);
    return _processedFrames / duration.inSeconds;
  }

  void _logPerformanceMetrics() {
    debugPrint('''
QR Scanner Performance Metrics:
-----------------------------
Total Frames: $_totalFrames
Processed Frames: $_processedFrames
Dropped Frames: $_droppedFrames
Successful Scans: $_successfulScans
Average Processing Time: ${averageProcessingTime.toStringAsFixed(2)}ms
Current Frame Rate: ${frameRate.toStringAsFixed(2)} fps
-----------------------------
''');
  }
} 