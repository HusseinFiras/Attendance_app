import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class PythonBackendManager {
  Process? _process;
  bool _isRunning = false;
  String? _executablePath;
  String? _lastError;
  String? _pythonPath;
  String? _pipPath;

  Future<bool> _findPython() async {
    try {
      debugPrint('Looking for Python installation...');
      
      // Try using py launcher first
      try {
        final pyResult = await Process.run('py', ['-3', '--version']);
        if (pyResult.exitCode == 0) {
          _pythonPath = 'py';
          
          // Get pip path using py
          final pipResult = await Process.run('py', ['-3', '-m', 'pip', '--version']);
          if (pipResult.exitCode == 0) {
            _pipPath = 'py -3 -m pip';
            debugPrint('Found Python using py launcher');
            return true;
          }
        }
      } catch (e) {
        debugPrint('py launcher not found, trying standard paths...');
      }
      
      // Common Python installation paths on Windows
      final possiblePaths = [
        r'C:\Python39\python.exe',
        r'C:\Python310\python.exe',
        r'C:\Python311\python.exe',
        r'C:\Python312\python.exe',
        r'C:\Python313\python.exe',
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python39\python.exe',
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310\python.exe',
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\python.exe',
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\python.exe',
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python313\python.exe',
        r'C:\Program Files\Python39\python.exe',
        r'C:\Program Files\Python310\python.exe',
        r'C:\Program Files\Python311\python.exe',
        r'C:\Program Files\Python312\python.exe',
        r'C:\Program Files\Python313\python.exe',
      ];

      // Replace %USERNAME% with actual username
      final username = Platform.environment['USERNAME'] ?? '';
      final paths = possiblePaths.map((p) => p.replaceAll('%USERNAME%', username)).toList();

      for (final pythonPath in paths) {
        if (await File(pythonPath).exists()) {
          _pythonPath = pythonPath;
          _pipPath = path.join(path.dirname(pythonPath), 'Scripts', 'pip.exe');
          
          // Verify pip exists
          if (await File(_pipPath!).exists()) {
            debugPrint('Found Python at: $_pythonPath');
            debugPrint('Found pip at: $_pipPath');
            return true;
          }
        }
      }

      _lastError = 'Python installation not found. Please install Python 3.9 or later from python.org';
      debugPrint(_lastError);
      return false;
    } catch (e) {
      _lastError = 'Error finding Python: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  Future<bool> _checkPythonDependencies() async {
    try {
      debugPrint('Checking Python dependencies...');
      
      // Find Python first
      if (!await _findPython()) {
        return false;
      }

      // Function to run Python commands
      Future<ProcessResult> runPython(List<String> args) async {
        if (_pythonPath == 'py') {
          return Process.run('py', ['-3', ...args]);
        } else {
          return Process.run(_pythonPath!, args);
        }
      }

      // Get Python installation info
      final pythonInfo = await runPython([
        '-c',
        'import sys; import os; print(os.path.dirname(sys.executable))'
      ]);
      final pythonPath = pythonInfo.stdout.toString().trim();
      final scriptsPath = path.join(pythonPath, 'Scripts');
      debugPrint('Python path: $pythonPath');
      debugPrint('Scripts path: $scriptsPath');

      // Check if pip is available
      final List<String> pipArgs = _pipPath == 'py -3 -m pip' 
          ? ['-3', '-m', 'pip', '--version']
          : ['--version'];
          
      final pipResult = _pipPath == 'py -3 -m pip'
          ? await Process.run('py', pipArgs)
          : await Process.run(_pipPath!, pipArgs);
          
      if (pipResult.exitCode != 0) {
        _lastError = 'pip is not available. Please reinstall Python.';
        debugPrint(_lastError);
        return false;
      }

      // Function to run pip commands
      Future<ProcessResult> runPip(List<String> args) async {
        if (_pipPath == 'py -3 -m pip') {
          return Process.run('py', ['-3', '-m', 'pip', ...args]);
        } else {
          return Process.run(_pipPath!, args);
        }
      }

      // First uninstall existing packages to avoid conflicts
      debugPrint('Uninstalling existing packages...');
      await runPip(['uninstall', '-y', 'opencv-python', 'pyzbar', 'pywin32']);

      // Upgrade pip and setuptools first
      debugPrint('Upgrading pip and setuptools...');
      await runPip(['install', '--upgrade', 'pip', 'setuptools', 'wheel']);

      // Install pywin32
      debugPrint('Installing pywin32...');
      final pywin32Result = await runPip(['install', '--no-cache-dir', 'pywin32']);
      if (pywin32Result.exitCode != 0) {
        _lastError = 'Failed to install pywin32: ${pywin32Result.stderr}';
        debugPrint(_lastError);
        return false;
      }

      // Verify pywin32 installation
      try {
        final verifyResult = await runPython(['-c', 'import win32pipe']);
        if (verifyResult.exitCode != 0) {
          throw Exception('win32pipe module not found');
        }
      } catch (e) {
        debugPrint('Warning: pywin32 verification failed: $e');
        // Continue anyway as it might still work
      }

      // Install opencv-python-headless (more compatible than opencv-python)
      debugPrint('Installing opencv-python-headless...');
      final opencvResult = await runPip(['install', 'opencv-python-headless']);
      if (opencvResult.exitCode != 0) {
        _lastError = 'Failed to install opencv-python-headless: ${opencvResult.stderr}';
        debugPrint(_lastError);
        return false;
      }

      // Install pyzbar
      debugPrint('Installing pyzbar...');
      final pyzbarResult = await runPip(['install', 'pyzbar']);
      if (pyzbarResult.exitCode != 0) {
        _lastError = 'Failed to install pyzbar: ${pyzbarResult.stderr}';
        debugPrint(_lastError);
        return false;
      }

      // Verify all imports work
      debugPrint('Verifying installations...');
      final verifyAll = await runPython([
        '-c',
        '''
import sys
print("Python version:", sys.version)
import numpy
print("NumPy version:", numpy.__version__)
import cv2
print("OpenCV version:", cv2.__version__)
import pyzbar
print("pyzbar version:", pyzbar.__version__)
import win32pipe
print("All imports successful!")
        '''
      ]);
      
      if (verifyAll.exitCode != 0) {
        _lastError = 'Failed to verify installations: ${verifyAll.stderr}';
        debugPrint(_lastError);
        return false;
      }
      
      debugPrint('Verification output: ${verifyAll.stdout}');
      debugPrint('All dependencies installed and verified successfully');
      return true;
    } catch (e) {
      _lastError = 'Error checking Python dependencies: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  Future<bool> startBackend() async {
    if (_isRunning) {
      debugPrint('Backend is already running');
      return true;
    }

    try {
      // Check Python dependencies first
      if (!await _checkPythonDependencies()) {
        return false;
      }

      // Create a temporary directory for our backend files
      final tempDir = Directory.systemTemp.createTempSync('qr_scanner');
      debugPrint('Created temp directory: ${tempDir.path}');

      // Write the Python script
      final scriptFile = File(path.join(tempDir.path, 'qr_server.py'));
      await scriptFile.writeAsString('''
import win32pipe, win32file, pywintypes, win32api, win32con
import cv2
from pyzbar import pyzbar
import json
import sys
import time
import numpy as np
import uuid
import os
import signal

# Global flag to track if we should keep running
running = True

def signal_handler(signum, frame):
    global running
    print("Received signal to stop", file=sys.stderr)
    running = False

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# Generate a unique pipe name for this session
PIPE_NAME = f'\\\\\\\\.\\\\pipe\\\\flutter_qr_pipe_{uuid.uuid4().hex}'

def create_pipe():
    global PIPE_NAME
    max_attempts = 5
    attempt = 0
    
    while attempt < max_attempts:
        try:
            # Try to create the pipe
            pipe = win32pipe.CreateNamedPipe(
                PIPE_NAME,
                win32pipe.PIPE_ACCESS_DUPLEX,
                win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
                1, 65536, 65536,
                0,
                None
            )
            print(f"Successfully created pipe: {PIPE_NAME}", file=sys.stderr)
            # Write the pipe name to stdout so the parent process can read it
            print(f"PIPE_READY:{PIPE_NAME}")
            sys.stdout.flush()
            return pipe
        except Exception as e:
            print(f"Error creating pipe (attempt {attempt + 1}/{max_attempts}): {e}", file=sys.stderr)
            attempt += 1
            if attempt < max_attempts:
                # If pipe exists, try a new name
                PIPE_NAME = f'\\\\\\\\.\\\\pipe\\\\flutter_qr_pipe_{uuid.uuid4().hex}'
                print(f"Trying new pipe name: {PIPE_NAME}", file=sys.stderr)
                time.sleep(1)  # Wait before retry
    
    raise Exception(f"Failed to create pipe after {max_attempts} attempts")

def cleanup_pipe(pipe):
    if pipe is not None:
        try:
            win32pipe.DisconnectNamedPipe(pipe)
        except:
            pass
        try:
            win32file.CloseHandle(pipe)
        except:
            pass

def process_frame(frame):
    # Convert to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # Detect QR codes
    qr_codes = pyzbar.decode(gray)
    
    results = []
    for qr in qr_codes:
        results.append({
            'type': qr.type,
            'data': qr.data.decode('utf-8'),
            'rect': {
                'left': qr.rect.left,
                'top': qr.rect.top,
                'width': qr.rect.width,
                'height': qr.rect.height
            }
        })
    
    return results

def main():
    print("Starting QR scanner server...", file=sys.stderr)
    print(f"Initial pipe name: {PIPE_NAME}", file=sys.stderr)
    
    while running:
        pipe = None
        try:
            pipe = create_pipe()
            print("Waiting for client connection...", file=sys.stderr)
            
            while running:
                try:
                    win32pipe.ConnectNamedPipe(pipe, None)
                    print("Client connected", file=sys.stderr)
                    
                    while running:
                        try:
                            # Read frame data
                            start_time = time.time()
                            
                            # Read frame size
                            size_data = win32file.ReadFile(pipe, 4)[1]
                            frame_size = int.from_bytes(size_data, byteorder='little')
                            
                            # Read frame data
                            frame_data = b''
                            while len(frame_data) < frame_size:
                                chunk = win32file.ReadFile(pipe, frame_size - len(frame_data))[1]
                                if not chunk:
                                    break
                                frame_data += chunk
                            
                            # Convert to numpy array
                            frame_array = np.frombuffer(frame_data, dtype=np.uint8)
                            frame = cv2.imdecode(frame_array, cv2.IMREAD_COLOR)
                            
                            if frame is None:
                                raise Exception("Failed to decode frame")
                            
                            # Process frame
                            results = process_frame(frame)
                            
                            # Calculate timing
                            processing_time = (time.time() - start_time) * 1000
                            
                            # Prepare response
                            response = {
                                'results': results,
                                'processingTimeMs': processing_time,
                                'averageTimeMs': processing_time
                            }
                            
                            # Send response
                            response_json = json.dumps(response)
                            response_data = response_json.encode('utf-8')
                            response_size = len(response_data)
                            
                            win32file.WriteFile(pipe, response_size.to_bytes(4, byteorder='little'))
                            win32file.WriteFile(pipe, response_data)
                            
                        except Exception as e:
                            print(f"Error processing frame: {e}", file=sys.stderr)
                            break
                    
                except Exception as e:
                    print(f"Client connection error: {e}", file=sys.stderr)
                finally:
                    cleanup_pipe(pipe)
                    pipe = None
            
        except Exception as e:
            print(f"Server error: {e}", file=sys.stderr)
        finally:
            cleanup_pipe(pipe)
            if running:
                time.sleep(1)  # Wait before retrying

    print("Server shutting down...", file=sys.stderr)

if __name__ == '__main__':
    main()
''');
      
      debugPrint('Created Python script at: ${scriptFile.path}');
      
      // Start the process using py -3
      debugPrint('Starting backend process...');
      _process = await Process.start(
        'py',
        ['-3', scriptFile.path],
        runInShell: true,
      );

      String? pipeName;
      bool pipeReady = false;
      bool componentsInitialized = false;
      final completer = Completer<bool>();

      // Listen for process output
      _process?.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        debugPrint('Backend stdout: $output');
        
        // Look for initialization messages
        if (output.contains('OpenCV initialized successfully') &&
            output.contains('pyzbar initialized successfully') &&
            output.contains('win32pipe initialized successfully')) {
          componentsInitialized = true;
        }
        
        // Look for pipe ready message
        if (output.contains('PIPE_READY:')) {
          pipeName = output.split('PIPE_READY:')[1].trim();
          debugPrint('Pipe ready: $pipeName');
          pipeReady = true;
          
          // Write pipe name to file
          final pipeFile = File('pipe_name.txt');
          pipeFile.writeAsStringSync(pipeName!);
          
          if (!completer.isCompleted && componentsInitialized) {
            completer.complete(true);
          }
        }
      });

      _process?.stderr.listen((data) {
        final error = String.fromCharCodes(data);
        debugPrint('Backend stderr: $error');
        if (error.contains('Failed to initialize components') || 
            error.contains('Server error:')) {
          _lastError = error;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });

      // Wait for process to start and pipe to be created
      debugPrint('Waiting for backend to initialize...');
      
      // Wait for either pipe ready or timeout
      bool success = false;
      try {
        success = await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 15)).then((_) {
            if (!completer.isCompleted) {
              debugPrint('Backend initialization timed out');
              completer.complete(false);
            }
            return false;
          }),
        ]);
      } catch (e) {
        debugPrint('Error waiting for backend: $e');
        success = false;
      }
      
      // Check if process is still running and pipe was created
      if (!success || _process?.exitCode != null || !pipeReady || !componentsInitialized) {
        _lastError = 'Backend process failed to initialize properly';
        if (!pipeReady) _lastError = '$_lastError (Pipe not ready)';
        if (!componentsInitialized) _lastError = '$_lastError (Components not initialized)';
        if (_process?.exitCode != null) _lastError = '$_lastError (Process exited with code ${_process?.exitCode})';
        debugPrint(_lastError);
        await stopBackend();
        return false;
      }
      
      // Give the pipe a moment to be fully ready
      await Future.delayed(const Duration(seconds: 1));
      
      _isRunning = true;
      debugPrint('Backend started successfully');
      return true;
    } catch (e) {
      _lastError = 'Error starting backend: $e';
      debugPrint(_lastError);
      _isRunning = false;
      return false;
    }
  }

  Future<void> stopBackend() async {
    if (_process != null) {
      try {
        debugPrint('Stopping backend process...');
        _process?.kill();
        await _process?.exitCode;
        debugPrint('Backend process stopped');
      } catch (e) {
        _lastError = 'Error stopping backend: $e';
        debugPrint(_lastError);
      } finally {
        _process = null;
        _isRunning = false;
      }
    }
  }

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
} 