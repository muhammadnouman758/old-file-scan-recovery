
import 'package:flutter/services.dart';

class UpdateMediaStore{

  static const MethodChannel _channel = MethodChannel("com.old.file_scanner/media_scanner");
  static Future<void> addToGallery(String filePath) async {
    try {
      await _channel.invokeMethod('refreshMedia', {
        "filePath": filePath,
        "actionType": "add",
      });
    } catch (e) {
      return ;
    }
  }
  /// Function to remove image from gallery (when moved to vault)
 static Future<void> removeFromGallery(String filePath) async {
    try {
      await _channel.invokeMethod('refreshMedia', {
        "filePath": filePath,
        "actionType": "remove",
      });

    } catch (e) {
      return ;
    }
  }
}