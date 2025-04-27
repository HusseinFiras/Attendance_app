import 'package:flutter/material.dart';
import '../services/qr_service.dart';
import '../services/report_service.dart';

class ServiceProvider extends ChangeNotifier {
  final QRService qrService = QRService();
  final ReportService reportService = ReportService();
} 