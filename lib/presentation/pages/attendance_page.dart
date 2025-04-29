import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../../core/services/qr_service.dart';
import '../../../core/services/camera_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize current date and time
    _updateDateTime();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _timeController.text = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    _dateController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _onQRCodeDetected(String qrData) {
    try {
      if (QRService.isValidEmployeeQR(qrData)) {
        final employeeId = QRService.getEmployeeId(qrData);
        if (employeeId != null) {
          setState(() {
            _idController.text = employeeId.toString();
            _updateDateTime();
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing QR data: $e');
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _notesController.dispose();
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
                            onQRCodeDetected: _onQRCodeDetected,
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
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;
  DateTime? _lastProcessedTime;
  static const Duration _processingCooldown = Duration(milliseconds: 500);
  bool _isInitializing = false;
  bool _isCameraActive = false;
  final CameraService _cameraService = CameraService();
  RouteObserver<ModalRoute<void>>? _routeObserver;

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeObserver?.unsubscribe(this);
    _disposeCamera();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when navigating away from this page
    _disposeCamera();
  }

  @override
  void didPopNext() {
    // Called when returning to this page
    if (!_isCameraActive && mounted) {
      Future.delayed(const Duration(milliseconds: 500), _initializeCamera);
    }
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

  Future<void> _initializeCamera() async {
    if (_isInitializing || _isCameraActive) return;
    _isInitializing = true;
    
    try {
      if (_controller != null) {
        await _disposeCamera();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        _isInitializing = false;
        return;
      }

      final indexToUse = _selectedCameraIndex < _cameras.length ? _selectedCameraIndex : 0;
      
      final controller = CameraController(
        _cameras[indexToUse],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isWindows ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      _controller = controller;
      _cameraService.registerCamera(controller);

      await controller.initialize();
      
      if (mounted) {
        setState(() {
          _selectedCameraIndex = indexToUse;
          _isInitialized = true;
          _isCameraActive = true;
        });
        await _startImageStream();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isCameraActive = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_isCameraActive) return;
    
    try {
      await _controller!.startImageStream((CameraImage image) async {
        // Check processing cooldown
        final now = DateTime.now();
        if (_isProcessing || 
            (_lastProcessedTime != null && 
             now.difference(_lastProcessedTime!) < _processingCooldown)) {
          return;
        }
        
        _isProcessing = true;
        _lastProcessedTime = now;

        try {
          final InputImage inputImage = InputImage.fromBytes(
            bytes: image.planes[0].bytes,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: InputImageRotation.rotation0deg,
              format: Platform.isWindows ? InputImageFormat.bgra8888 : InputImageFormat.yuv420,
              bytesPerRow: image.planes[0].bytesPerRow,
            ),
          );

          final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
          
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && 
                mounted &&
                QRService.isValidEmployeeQR(barcode.rawValue!)) {
              widget.onQRCodeDetected(barcode.rawValue!);
              break;
            }
          }
        } catch (e) {
          debugPrint('Error processing image: $e');
        } finally {
          _isProcessing = false;
        }
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _isCameraActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameras.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'لا توجد كاميرات متاحة',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Column(
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
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        if (!_isInitializing)
                          ElevatedButton(
                            onPressed: _initializeCamera,
                            child: const Text('إعادة محاولة تشغيل الكاميرا'),
                          ),
                      ],
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CameraPreview(_controller!),
                ),
        ),
      ],
    );
  }
}