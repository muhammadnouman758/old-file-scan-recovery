
import 'package:shared_preferences/shared_preferences.dart';

class SettingBySharedPreference{

  static get notificationKey => "notification";
  static get darkModeKey => "dark_mode";
  static get deleteDuplicateKey => "deleteDuplicates";
  static get saveFileKey => "save_file";
  static get scanDepthKey => 'scan_depth';

  static Future<void> updateSharedPreferencesData(String key,dynamic val)
  async {
    final object = await SharedPreferences.getInstance();
  if(val is bool){
    object.setBool(key,val);
  }
  else if(val is String){
    object.setString(key,val);
  }
  }
  static Future<bool> getSharedPreferencesDataBool(String key)
  async{
    final object = await SharedPreferences.getInstance();
    return object.getBool(key)!;
  }
  static Future<String> getSharedPreferencesDataString(String key)
  async{
    final object = await SharedPreferences.getInstance();
    return object.getString(key)!;
  }

  }