import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'dart:ui' as ui;

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

  void _onQRCodeDetected(String employeeId) {
    setState(() {
      _idController.text = employeeId;
      _updateDateTime();
    });
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

class _QRScannerWidgetState extends State<QRScannerWidget> {
  CameraController? _controller;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      await _switchCamera(_selectedCameraIndex);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _selectedCameraIndex = index;
          _isInitialized = true;
        });
        await _startImageStream();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startImageStream() async {
    await _controller?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final InputImage inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
        
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
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
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
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
                  _switchCamera(index);
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
                  child: const Center(
                    child: CircularProgressIndicator(),
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