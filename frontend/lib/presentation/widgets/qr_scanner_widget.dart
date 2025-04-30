import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/camera_service.dart';
import '../../core/qr/python_qr_scanner.dart';
import '../../core/backend/python_backend_manager.dart';
import 'package:url_launcher/url_launcher.dart';

// Register the Windows camera plugin
void _initializeWindowsCamera() {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    CameraPlatform.instance = CameraWindows();
  }
}

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRCodeDetected;

  const QRScannerWidget({
    Key? key,
    required this.onQRCodeDetected,
  }) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = false;
  bool _isCameraActive = false;
  
  final CameraService _cameraService = CameraService();
  final PythonBackendManager _backendManager = PythonBackendManager();
  late PythonQRScanner _qrScanner;
  
  bool _showSuccessAnimation = false;
  String? _lastError;
  bool _backendStarted = false;
  bool _isProcessing = false;
  bool _isDisposed = false;
  
  // New status tracking variables
  bool _isBackendInitializing = false;
  bool _isBackendInitialized = false;
  bool _isCameraInitializing = false;
  bool _isPipeAvailable = false;
  String _statusMessage = 'Initializing...';
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeWindowsCamera();
    WidgetsBinding.instance.addObserver(this);
    
    _qrScanner = PythonQRScanner(
      onQRDetected: widget.onQRCodeDetected,
    );
    
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    if (_isDisposed) return;
    
    setState(() {
      _isBackendInitializing = true;
      _statusMessage = 'Initializing backend...';
      _lastError = null;
    });

    try {
      // Initialize backend first
      final backendResult = await _qrScanner.initialize();
      
      if (!backendResult) {
        throw Exception('Failed to initialize backend');
      }

      setState(() {
        _isBackendInitialized = true;
        _isBackendInitializing = false;
        _isCameraInitializing = true;
        _statusMessage = 'Initializing camera...';
      });

      // Then initialize camera
      await _initializeCamera();
      
      setState(() {
        _isCameraInitializing = false;
        _statusMessage = 'Ready to scan';
      });
    } catch (e) {
      debugPrint('Scanner initialization error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _lastError = e.toString();
          _statusMessage = 'Initialization failed';
          _isBackendInitializing = false;
          _isCameraInitializing = false;
        });
        
        // Retry initialization if attempts haven't been exhausted
        if (_initializationAttempts < _maxInitializationAttempts) {
          _initializationAttempts++;
          Future.delayed(const Duration(seconds: 2), _initializeScanner);
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final indexToUse = _selectedCameraIndex < _cameras.length ? _selectedCameraIndex : 0;
      
      final controller = CameraController(
        _cameras[indexToUse],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.windows 
          ? ImageFormatGroup.bgra8888 
          : ImageFormatGroup.yuv420,
      );

      _controller = controller;
      _cameraService.registerCamera(controller);

      await controller.initialize();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedCameraIndex = indexToUse;
          _isInitialized = true;
          _isCameraActive = true;
        });
        
        // Only start image stream after both backend and camera are ready
        if (_isBackendInitialized) {
          await _startImageStream();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = false;
          _isCameraActive = false;
          _lastError = e.toString();
        });
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _qrScanner.dispose();
    _backendManager.stopBackend();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null) {
        _initializeScanner();
      }
    }
  }

  void _onSuccessfulScan() {
    if (_isDisposed) return;
    
    setState(() {
      _showSuccessAnimation = true;
    });
    
    // Reset animation after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_isDisposed) {
        setState(() {
          _showSuccessAnimation = false;
        });
      }
    });
  }

  Future<void> _disposeCamera() async {
    try {
      _isCameraActive = false;
      
      final controller = _controller;
      if (controller != null) {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
        _controller = null;
        _isInitialized = false;
        await _cameraService.cleanupCamera();
      }
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_isCameraActive || _isDisposed) return;
    
    try {
      await _controller!.startImageStream((CameraImage image) async {
        if (!_isProcessing && !_isDisposed) {
          try {
            await _qrScanner.processFrame(image);
          } catch (e) {
            debugPrint('QR processing error: $e');
            // Attempt to restart backend if needed
            if (e.toString().contains('pipe')) {
              await _initializeScanner();
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _isCameraActive = false;
      if (mounted && !_isDisposed) {
        setState(() {
          _lastError = 'Failed to start camera stream';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (_cameras.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DropdownButtonFormField<int>(
                  value: _selectedCameraIndex,
                  decoration: InputDecoration(
                    labelText: 'اختر الكاميرا',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: List.generate(
                    _cameras.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(
                        'كاميرا ${index + 1} - ${_cameras[index].name}',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  onChanged: (index) {
                    if (index != null && !_isDisposed) {
                      _selectedCameraIndex = index;
                      _initializeScanner();
                    }
                  },
                ),
              ),
            Expanded(
              child: !_isInitialized || _controller == null
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isInitializing || _isBackendInitializing || _isCameraInitializing)
                              const CircularProgressIndicator()
                            else
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (_lastError != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lastError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_qrScanner.backendManager.lastError != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Backend Error:',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _qrScanner.backendManager.lastError!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_qrScanner.backendManager.lastError!.contains('pip') ||
                                        _qrScanner.backendManager.lastError!.contains('Python'))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Python Installation Required:',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '1. Download and install Python 3.9 or later from python.org\n'
                                              '2. During installation, check "Add Python to PATH"\n'
                                              '3. Restart the application after installation',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.error,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: () async {
                                                // Open Python download page
                                                final url = Uri.parse('https://www.python.org/downloads/');
                                                if (await canLaunch(url.toString())) {
                                                  await launch(url.toString());
                                                }
                                              },
                                              icon: const Icon(Icons.download),
                                              label: const Text('Download Python'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (!_isInitializing && !_isBackendInitializing && !_isCameraInitializing)
                              ElevatedButton.icon(
                                onPressed: _initializeScanner,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة محاولة التشغيل'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Camera preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CameraPreview(_controller!),
                        ),
                        
                        // QR Code scanning overlay
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          width: 200,
                          height: 200,
                        ),
                        
                        // Status overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isBackendInitialized ? Icons.check_circle : Icons.error,
                                      color: _isBackendInitialized ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _statusMessage,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (_qrScanner.backendManager.lastError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Backend: ${_qrScanner.backendManager.lastError}',
                                      style: const TextStyle(color: Colors.red, fontSize: 10),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Debug info overlay
                        if (_qrScanner.lastResponse != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FPS: ${(1000 / (_qrScanner.lastResponse?.averageTimeMs ?? 1000)).toStringAsFixed(1)} | Proc: ${_qrScanner.lastResponse?.processingTimeMs.toStringAsFixed(1)}ms',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  if (_qrScanner.lastResponse?.results.isNotEmpty ?? false)
                                    Text(
                                      'QR: ${_qrScanner.lastResponse!.results.first.data.length > 30 ? _qrScanner.lastResponse!.results.first.data.substring(0, 30) + '...' : _qrScanner.lastResponse!.results.first.data}',
                                      style: const TextStyle(color: Colors.green, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        
        // Success animation overlay
        if (_showSuccessAnimation)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showSuccessAnimation ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.green.withOpacity(0.3),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 100,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 