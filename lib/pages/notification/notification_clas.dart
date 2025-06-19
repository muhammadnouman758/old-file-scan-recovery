
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_stat_notification');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // print("User clicked: ${response.payload}");
      },
    );
  }
  Future<void> showScanNotification(int totalFiles) async {
     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scan_results_channel', // Unique Channel ID
      'Scan Results', // Channel Name
      channelDescription: 'Notification for completed scans',
      importance: Importance.high,
       icon: '@drawable/ic_stat_notification',
      priority: Priority.high,
      ticker: 'scan_complete',
      styleInformation: const BigTextStyleInformation(''),
      color: CusColor.darkBlue3, // Modern Accent Color
      enableVibration: true, // Vibrate for Attention
      actions: [
        const AndroidNotificationAction(
          'open_action', ' Open Results',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss_action', ' Dismiss',
          cancelNotification: true,
        ),
      ],
    );
    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
   await _notificationsPlugin.show(
      0,
      'Scan Completed ',
      'Total $totalFiles files Scanned!',
      notificationDetails,
      payload: "open_scan_results",
    );
  }
  Future<void> showScanNotificationSecured(int totalFiles) async {
     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'secured_results_channel', // Unique Channel ID
      'Secured Results', // Channel Name
      channelDescription: 'Notification for  Secured in Vault',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'file Secured In Vault',
      styleInformation: const BigTextStyleInformation(''),
       icon: '@drawable/ic_stat_notification',
      color: CusColor.darkBlue3, // Modern Accent Color
      enableVibration: true, // Vibrate for Attention
      actions: [
        const AndroidNotificationAction(
          'open_action', ' Open Results',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss_action', ' Dismiss',
          cancelNotification: true,
        ),
      ],
    );
    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
   await _notificationsPlugin.show(
      0,
      'Secured In Vault ',
      'Total $totalFiles files Secured!',
      notificationDetails,
      payload: "open_scan_results",
    );
  }
}
