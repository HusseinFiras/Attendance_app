// This is a basic Flutter widget test for the Attendance System.
//
// Tests basic widget rendering and interactions in the attendance system app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_system/main.dart';
import 'package:provider/provider.dart';
import 'package:attendance_system/core/services/navigation_service.dart';
import 'package:attendance_system/core/providers/database_provider.dart';
import 'package:attendance_system/core/providers/repository_provider.dart';
import 'package:attendance_system/core/providers/service_provider.dart';

void main() {
  testWidgets('Attendance System App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavigationService()),
          ChangeNotifierProvider(create: (_) => DatabaseProvider()),
          ProxyProvider<DatabaseProvider, RepositoryProvider>(
            update: (context, db, previous) => RepositoryProvider(db.database),
          ),
          ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ],
        child: const AttendanceApp(),
      ),
    );

    // Verify that the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify navigation rail destinations are present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
