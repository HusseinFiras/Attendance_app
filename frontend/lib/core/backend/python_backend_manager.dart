import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class PythonBackendManager {
  static const String _exeName = 'qr_server.exe';
  static const String _assetPath = 'assets/backend/qr_server.exe';
  
  Process? _process;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  
  Future<bool> startBackend() async {
    if (_isRunning) {
      return true; // Already running
    }
    
    try {
      // Get app storage directory
      final directory = await getApplicationSupportDirectory();
      final exePath = '${directory.path}\\$_exeName';
      
      // Check if executable exists, extract if not
      final file = File(exePath);
      if (!await file.exists()) {
        debugPrint('Extracting Python backend executable...');
        try {
          // Create directory if it doesn't exist
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          // Extract executable from assets
          final byteData = await rootBundle.load(_assetPath);
          final buffer = byteData.buffer.asUint8List();
          await file.writeAsBytes(buffer);
          debugPrint('Python backend executable extracted successfully');
        } catch (e) {
          debugPrint('Failed to extract Python backend: $e');
          return false;
        }
      }
      
      // Start the process
      debugPrint('Starting Python backend...');
      _process = await Process.start(
        exePath,
        [],
        runInShell: true,
      );
      
      // Monitor process output
      _process!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('Python stdout: $data');
      });
      
      _process!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('Python stderr: $data');
      });
      
      // Monitor process exit
      _process!.exitCode.then((exitCode) {
        debugPrint('Python backend exited with code: $exitCode');
        _isRunning = false;
      });
      
      _isRunning = true;
      debugPrint('Python backend started successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to start Python backend: $e');
      return false;
    }
  }
  
  Future<void> stopBackend() async {
    if (!_isRunning || _process == null) {
      return;
    }
    
    try {
      debugPrint('Stopping Python backend...');
      _process!.kill();
      _isRunning = false;
      debugPrint('Python backend stopped');
    } catch (e) {
      debugPrint('Failed to stop Python backend: $e');
    }
  }
} 