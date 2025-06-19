import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/dumy.dart';
import 'package:old_file_recovery/first/splash_screen.dart';
import 'package:old_file_recovery/pages/database/access_pin.dart';
import 'package:old_file_recovery/pages/database/database_manager.dart';
import 'package:old_file_recovery/pages/database/valut_access.dart';
import 'package:old_file_recovery/pages/history/scan_records.dart';
import 'package:old_file_recovery/pages/notification/notification_clas.dart';
import 'package:old_file_recovery/pages/privacy/help_support.dart';
import 'package:old_file_recovery/pages/privacy/privacy.dart';
import 'package:old_file_recovery/pages/recover_file/ui_recovered_file.dart';
import 'package:old_file_recovery/pages/vault/move_file_to_vault/animation_page_vault.dart';
import 'package:old_file_recovery/pages/vault/vault_category.dart';
import 'package:old_file_recovery/setting/event/event_setting.dart';
import 'package:old_file_recovery/setting/setting.dart';
import 'package:old_file_recovery/setting/ui/setting_ui.dart';
import 'app_update.dart';
import 'pages/history/bloc/ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DatabaseManager dbManager = DatabaseManager();
  await dbManager.initializeDatabase();
  await NotificationService().initialize();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsBloc()..add(LoadSettings())),
        BlocProvider(create: (context) => ScanHistoryBloc())
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final currentDate = DateTime.now();
  final cutoffDate = DateTime(2025, 5, 20);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        title: 'Old File Scan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          fontFamily: 'font',
          useMaterial3: true,
        ),
        initialRoute: currentDate.isAfter(cutoffDate) ? '/app-in-update' :'/home',
        routes: {
          '/home': (context) => const SplashScreen(),
          '/access': (context) => const VaultAccessScreen(),
          '/set-pin': (context) => const SetPinScreen(),
          '/vault': (context) => const VaultCategory(),
          '/SettingsPage': (context) => const SettingsPage(),
          '/PrivacyPage': (context) => const PrivacyPolicyScreen(),
          '/Support': (context) => const HelpSupportScreen(),
          '/ScanResults': (context) => const ScanHistoryScreen(),
          '/anim': (context) => const VaultTrackingPage(),
          '/recovered': (context) => const RecoveryDashboard(),
          '/app-in-update': (context) => const AppUpdateScreen(),
          '/media': (context) => const MyApp(),
          '/Social': (context) => const SocialMedia(),
        },
      ),
    );
  }
}