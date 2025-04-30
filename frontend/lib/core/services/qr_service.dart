import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRService {
  static String generateEmployeeQRData({
    required int employeeId,
    required String name,
    required String department,
  }) {
    final data = {
      'id': employeeId,
      'name': name,
      'department': department,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  static Widget generateQRCode(String data) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    );
  }

  static Map<String, dynamic>? parseQRData(String data) {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static bool isValidEmployeeQR(String data) {
    try {
      final qrData = jsonDecode(data) as Map<String, dynamic>;
      return qrData.containsKey('id') &&
          qrData.containsKey('name') &&
          qrData.containsKey('department') &&
          qrData.containsKey('timestamp');
    } catch (e) {
      return false;
    }
  }

  static DateTime? getQRTimestamp(String data) {
    try {
      final qrData = jsonDecode(data) as Map<String, dynamic>;
      return DateTime.parse(qrData['timestamp'] as String);
    } catch (e) {
      return null;
    }
  }

  static int? getEmployeeId(String data) {
    try {
      final qrData = jsonDecode(data) as Map<String, dynamic>;
      return qrData['id'] as int;
    } catch (e) {
      return null;
    }
  }
} 