import 'package:flutter/material.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/employees_page.dart';
import '../../presentation/pages/attendance_page.dart';
import '../../presentation/pages/reports_page.dart';
import '../../presentation/pages/settings_page.dart';

class NavigationService extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final List<Widget> _pages = [
    const DashboardPage(),
    const EmployeesPage(),
    const AttendancePage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  Widget get currentPage => _pages[_currentIndex];

  void navigateToIndex(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
} 