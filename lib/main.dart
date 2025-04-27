import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/navigation_service.dart';
import 'core/services/localization_service.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/repository_provider.dart';
import 'core/providers/service_provider.dart';
import 'presentation/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationService()),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationService()),
        ProxyProvider<DatabaseProvider, RepositoryProvider>(
          update: (context, db, previous) => RepositoryProvider(db.database),
        ),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
      ],
      child: const AttendanceApp(),
    ),
  );
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = context.watch<LocalizationService>();
    
    return MaterialApp(
      title: localizationService.translate('appName'),
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Cairo',
        textTheme: const TextTheme().apply(
          fontFamily: 'Cairo',
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Cairo',
        textTheme: const TextTheme().apply(
          fontFamily: 'Cairo',
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Directionality(
          textDirection: localizationService.textDirection,
          child: child!,
        );
      },
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = context.watch<LocalizationService>();
    
    return Consumer<NavigationService>(
      builder: (context, navigationService, child) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationService.currentIndex,
                onDestinationSelected: navigationService.navigateToIndex,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.dashboard),
                    label: const Text('لوحة التحكم'),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.people),
                    label: const Text('المقاتلين'),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.qr_code),
                    label: const Text('الدوام'),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.assessment),
                    label: const Text('التقارير'),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings),
                    label: const Text('الإعدادات'),
                  ),
                ],
              ),
              Expanded(
                child: navigationService.currentPage,
              ),
            ],
          ),
        );
      },
    );
  }
}
