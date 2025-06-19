import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io' show Platform;
class StoragePermissionHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    if (await isAndroid11OrAbove()) {
      return await requestManageExternalStorage();
    } else {
      return await requestReadWritePermission();
    }
  }

  static Future<bool> requestReadWritePermission() async {
    PermissionStatus status = await Permission.storage.request();
    return status.isGranted;
  }
  static Future<bool> requestManageExternalStorage() async {
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  static Future<bool> isAndroid11OrAbove() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.version.sdkInt >= 30;
      }
      return false;
    } catch (e) {

      return false;
    }
  }

  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await isAndroid11OrAbove()) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}