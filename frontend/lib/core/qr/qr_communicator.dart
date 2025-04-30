import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class QRResponse {
  final List<QRResult> results;
  final double processingTimeMs;
  final double averageTimeMs;

  QRResponse({
    required this.results,
    required this.processingTimeMs,
    required this.averageTimeMs,
  });

  factory QRResponse.fromJson(Map<String, dynamic> json) {
    return QRResponse(
      results: (json['results'] as List)
          .map((result) => QRResult.fromJson(result))
          .toList(),
      processingTimeMs: json['processing_time_ms']?.toDouble() ?? 0.0,
      averageTimeMs: json['average_time_ms']?.toDouble() ?? 0.0,
    );
  }
}

class QRResult {
  final String data;
  final bool isValid;

  QRResult({
    required this.data,
    required this.isValid,
  });

  factory QRResult.fromJson(Map<String, dynamic> json) {
    return QRResult(
      data: json['data'] ?? '',
      isValid: json['is_valid'] ?? false,
    );
  }
}

class QRCommunicator {
  String? _pipeName;
  static const Duration _timeout = Duration(seconds: 5);

  Future<bool> isPipeAvailable() async {
    try {
      if (_pipeName == null) {
        // Wait for pipe name from backend
        final pipeFile = File('pipe_name.txt');
        if (!await pipeFile.exists()) {
          return false;
        }
        _pipeName = await pipeFile.readAsString();
      }
      final file = File(_pipeName!);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking pipe availability: $e');
      return false;
    }
  }

  Future<QRResponse?> sendTestMessage() async {
    try {
      // Create a test request with a small black image
      final testImage = List<int>.filled(100 * 100 * 4, 0); // 100x100 black image in BGRA format
      final base64Image = base64Encode(testImage);
      
      final request = json.encode({
        'image': base64Image,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final response = await _sendMessage(request);
      if (response == null) {
        return null;
      }

      return QRResponse.fromJson(json.decode(response));
    } catch (e) {
      debugPrint('Error sending test message: $e');
      return null;
    }
  }

  Future<QRResponse?> sendFrame(CameraImage frame) async {
    try {
      // Convert frame to bytes
      final bytes = _convertFrameToBytes(frame);
      final base64Image = base64Encode(bytes);
      
      final request = json.encode({
        'image': base64Image,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final response = await _sendMessage(request);
      if (response == null) {
        return null;
      }

      return QRResponse.fromJson(json.decode(response));
    } catch (e) {
      debugPrint('Error sending frame: $e');
      return null;
    }
  }

  Future<String?> _sendMessage(String message) async {
    try {
      if (_pipeName == null) {
        // Try to read pipe name again
        final pipeFile = File('pipe_name.txt');
        if (!await pipeFile.exists()) {
          debugPrint('Pipe name file not found');
          return null;
        }
        _pipeName = await pipeFile.readAsString();
      }

      // Try to open the pipe with retries
      RandomAccessFile? pipe;
      int retries = 3;
      while (retries > 0) {
        try {
          pipe = await File(_pipeName!).open(mode: FileMode.write);
          break;
        } catch (e) {
          debugPrint('Failed to open pipe (attempt ${4 - retries}/3): $e');
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (pipe == null) {
        debugPrint('Failed to open pipe after all retries');
        return null;
      }
      
      // Write message
      await pipe.writeString(message);
      await pipe.flush();
      
      // Read response
      final buffer = StringBuffer();
      final bytes = await pipe.read(1024);
      while (bytes.isNotEmpty) {
        buffer.write(String.fromCharCodes(bytes));
        final nextBytes = await pipe.read(1024);
        if (nextBytes.isEmpty) break;
      }
      await pipe.close();
      
      return buffer.toString();
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  List<int> _convertFrameToBytes(CameraImage image) {
    // Handle BGRA format (Windows)
    if (image.format.group == ImageFormatGroup.bgra8888) {
      // For Windows, we get direct access to the pixel data
      return image.planes[0].bytes;
    }
    
    // Fallback for other formats (unlikely on Windows)
    throw UnsupportedError('Unsupported image format: ${image.format.group}');
  }
} 