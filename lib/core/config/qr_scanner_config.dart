import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class QRScannerConfig {
  static const Duration processingCooldown = Duration(milliseconds: 100);
  static const Duration initializationTimeout = Duration(seconds: 10);
  static const Duration recoveryDelay = Duration(milliseconds: 300);
  
  static const int maxInitializationAttempts = 3;
  static const int targetFPS = 15;
  
  // Windows-specific camera configuration
  static const ResolutionPreset resolution = ResolutionPreset.medium;
  static const ImageFormatGroup imageFormat = ImageFormatGroup.bgra8888;

  static const Map<String, dynamic> cameraConfig = {
    'enableAudio': false,
  };

  // Performance monitoring thresholds
  static const Duration maxProcessingTime = Duration(milliseconds: 100);
  static const Duration frameDropThreshold = Duration(milliseconds: 33); // ~30fps

  // Debug settings
  static const bool enablePerformanceLogging = true;
  static const bool enableFrameStatistics = true;
  static const int performanceLogInterval = 30; // Log every 30 frames
} 