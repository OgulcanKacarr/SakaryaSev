import 'package:arac_takip/services/DatabaseService/DatabaseService.dart';
import 'package:arac_takip/services/SharedPrefService.dart';
import 'package:arac_takip/services/TrioListenerService/TrioListenerService.dart';
import 'package:arac_takip/view/SplashPage.dart';
import 'package:arac_takip/view/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/AppLifecycleObserver.dart';
import 'constants/AppPagePath.dart';
import 'constants/AppThemes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isFirstLaunch =
  await _checkFirstLaunch();

  try {
    DatabaseService.instance.database;
    debugPrint('SakaryaSEV veritabanı başarıyla başlatıldı.');
    await TrioListenerService.instance.start(port: 5000);
    debugPrint('TRIO dinleyicisi başarıyla başlatıldı.');
  } catch (e, stackTrace) {
    debugPrint('Veritabanı başlatma hatası: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    ProviderScope(
      child: MyApp(isFirstRun: isFirstLaunch),
    ),
  );
}

Future<bool> _checkFirstLaunch() async {
  final bool isFirstLaunch =
  await SharedPrefService.readBool('isFirstLaunch');

  if (isFirstLaunch) {
    await SharedPrefService.saveBool(
      'isFirstLaunch',
      false,
    );
  }
  return isFirstLaunch;
}

class MyApp extends StatefulWidget {
  final bool isFirstRun;
  const MyApp({
    super.key,
    required this.isFirstRun,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleObserver _appLifecycleObserver;

  @override
  void initState() {
    super.initState();

    _appLifecycleObserver = AppLifecycleObserver(
      onBackground: () {},
      onForeground: () {},
    );

    WidgetsBinding.instance.addObserver(
      _appLifecycleObserver,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      _appLifecycleObserver,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: AppThemes.darkTheme,
      theme: AppThemes.lightTheme,
      home: widget.isFirstRun
          ? const SplashPage()
          : const HomePage(),
      routes: {
        AppPagePath.homePage.pathString:
            (context) => const HomePage(),
        AppPagePath.splashPage.pathString:
            (context) => const SplashPage(),
      },
    );
  }
}