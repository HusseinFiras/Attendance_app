import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../../core/services/qr_service.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/scanner_performance_service.dart';
import '../../core/config/qr_scanner_config.dart';
import '../../core/utils/image_converter.dart';
import '../widgets/qr_scanner_widget.dart';
import '../../core/qr/python_qr_scanner.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with WidgetsBindingObserver {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleQRCode(String qrData) {
    if (QRService.isValidEmployeeQR(qrData)) {
      final employeeId = QRService.getEmployeeId(qrData);
      if (employeeId != null) {
        setState(() {
          _idController.text = employeeId.toString();
          _updateDateTime();
        });
      }
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _timeController.text = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    _dateController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _idController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تسجيل الدوام',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Manual Entry Section
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدخال يدوي',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _idController,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            labelText: 'رقم المقاتل',
                            hintText: 'أدخل رقم المقاتل',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _timeController,
                                textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  labelText: 'الوقت',
                                  hintText: 'اختر الوقت',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: const Icon(Icons.access_time),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _dateController,
                                textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  labelText: 'التاريخ',
                                  hintText: 'اختر التاريخ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesController,
                          textDirection: TextDirection.rtl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات',
                            hintText: 'أدخل أي ملاحظات إضافية',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  // TODO: Implement manual check-out
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('تسجيل انصراف يدوي'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  // TODO: Implement manual check-in
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('تسجيل حضور يدوي'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // QR Scanner Section
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ماسح رمز QR',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: 1,
                          child: QRScannerWidget(
                            onQRCodeDetected: _handleQRCode,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  // TODO: Implement check-out
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('تسجيل انصراف'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  // TODO: Implement check-in
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('تسجيل حضور'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Records
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السجلات الأخيرة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index % 2 == 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Icon(
                                index % 2 == 0 ? Icons.login : Icons.logout,
                                color:
                                    index % 2 == 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            title: const Text('محمد أحمد علي'),
                            subtitle: Text(
                              index % 2 == 0
                                  ? 'تسجيل حضور - 9:00 صباحاً'
                                  : 'تسجيل انصراف - 5:00 مساءً',
                            ),
                            trailing: const Text('اليوم 9:00 صباحاً'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRCodeDetected;

  const QRScannerWidget({
    super.key,
    required this.onQRCodeDetected,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> with WidgetsBindingObserver, RouteAware {
  CameraController? _controller;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;
  bool _isInitializing = false;
  bool _isCameraActive = false;
  int _initializationAttempts = 0;
  
  final CameraService _cameraService = CameraService();
  final ScannerPerformanceService _performanceService = ScannerPerformanceService();
  RouteObserver<ModalRoute<void>>? _routeObserver;
  Timer? _initializationTimeout;
  
  // Debug and UI state
  bool _debugMode = true;
  String _lastDetectedData = '';
  bool _isCurrentlyScanning = false;
  String? _lastError;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = RouteObserver<ModalRoute<void>>();
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  void _cancelInitializationTimeout() {
    _initializationTimeout?.cancel();
    _initializationTimeout = null;
  }

  void _startInitializationTimeout() {
    _cancelInitializationTimeout();
    _initializationTimeout = Timer(QRScannerConfig.initializationTimeout, () {
      if (!_isInitialized && mounted) {
        debugPrint('Camera initialization timeout - attempting recovery');
        _resetInitialization();
      }
    });
  }

  void _resetInitialization() {
    _isInitializing = false;
    _initializationAttempts = 0;
    _performanceService.reset();
    if (mounted) {
      setState(() {
        _lastError = 'Camera initialization timed out';
      });
    }
  }

  Future<void> _disposeCamera() async {
    try {
      _isCameraActive = false;
      _cancelInitializationTimeout();
      
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

  Future<void> _initializeCamera() async {
    if (_isInitializing || _isCameraActive) return;
    if (_initializationAttempts >= QRScannerConfig.maxInitializationAttempts) {
      debugPrint('Max initialization attempts reached');
      _resetInitialization();
      return;
    }

    _isInitializing = true;
    _initializationAttempts++;
    _startInitializationTimeout();
    
    try {
      if (_controller != null) {
        await _disposeCamera();
        await Future.delayed(QRScannerConfig.recoveryDelay);
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final indexToUse = _selectedCameraIndex < _cameras.length ? _selectedCameraIndex : 0;
      
      final controller = CameraController(
        _cameras[indexToUse],
        QRScannerConfig.resolution,
        enableAudio: QRScannerConfig.cameraConfig['enableAudio'],
        imageFormatGroup: QRScannerConfig.imageFormat,
      );

      _controller = controller;
      _cameraService.registerCamera(controller);

      await controller.initialize();
      
      if (mounted) {
        setState(() {
          _selectedCameraIndex = indexToUse;
          _isInitialized = true;
          _isCameraActive = true;
          _lastError = null;
        });
        await _startImageStream();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isCameraActive = false;
          _lastError = e.toString();
        });
      }
      // Attempt recovery with delay
      if (_initializationAttempts < QRScannerConfig.maxInitializationAttempts) {
        Future.delayed(QRScannerConfig.recoveryDelay, _initializeCamera);
      }
    } finally {
      _isInitializing = false;
      _cancelInitializationTimeout();
    }
  }

  void _onSuccessfulScan() {
    setState(() {
      _showSuccessAnimation = true;
    });
    // Reset animation after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSuccessAnimation = false;
        });
      }
    });
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_isCameraActive) return;
    
    try {
      await _controller!.startImageStream((CameraImage image) async {
        if (_isProcessing) return;
        
        setState(() {
          _isCurrentlyScanning = true;
        });

        final processingStart = DateTime.now();
        _isProcessing = true;

        try {
          final inputImage = ImageConverter.convertCameraImage(image);
          if (inputImage == null) {
            debugPrint('Failed to convert camera image');
            return;
          }

          // Process QR code using Python backend
          final qrData = await QRService.parseQRData(inputImage);
          
          if (qrData != null && qrData['id'] != null) {
            final qrString = jsonEncode(qrData);
            if (qrString != _lastDetectedData) {
              if (_debugMode) {
                debugPrint('QR Code Detected: $qrString');
                _lastDetectedData = qrString;
                _performanceService.recordSuccessfulScan();
              }

              widget.onQRCodeDetected(qrString);
              _onSuccessfulScan();
            }
          }
        } catch (e) {
          debugPrint('Error processing image: $e');
        } finally {
          final processingTime = DateTime.now().difference(processingStart);
          _performanceService.recordFrameProcessed(processingTime);
          
          _isProcessing = false;
          setState(() {
            _isCurrentlyScanning = false;
          });
          
          // Adaptive frame delay based on processing time
          final delay = processingTime > QRScannerConfig.maxProcessingTime
              ? QRScannerConfig.processingCooldown
              : Duration(milliseconds: (1000 / QRScannerConfig.targetFPS).round());
          
          await Future.delayed(delay);
        }
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _isCameraActive = false;
      if (mounted) {
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
                    if (index != null) {
                      _selectedCameraIndex = index;
                      _initializeCamera();
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
                            if (_isInitializing)
                              const CircularProgressIndicator()
                            else
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            const SizedBox(height: 16),
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
                            if (!_isInitializing)
                              ElevatedButton.icon(
                                onPressed: _initializeCamera,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة محاولة تشغيل الكاميرا'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CameraPreview(_controller!),
                        ),
                        // QR Code scanning overlay
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isCurrentlyScanning 
                                ? Colors.green.withOpacity(0.5)
                                : Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          width: 200,
                          height: 200,
                        ),
                        // Debug information overlay
                        if (_debugMode)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_lastDetectedData.isNotEmpty)
                                    Text(
                                      'Last QR: $_lastDetectedData',
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'FPS: ${_performanceService.frameRate.toStringAsFixed(1)} | '
                                    'Proc: ${_performanceService.averageProcessingTime.toStringAsFixed(1)}ms',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
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
                child: Center(
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