import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../event/event_setting.dart';
import '../state/state_setting.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
      : super(const SettingsState(
    darkMode: false,
    autoSave: true,
    deleteDuplicates: false,
    notifications: true,
    scanDepth: "Medium",
  )) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSetting>(_onUpdateSetting);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emit(SettingsState(
      darkMode: prefs.getBool("darkMode") ?? false,
      autoSave: prefs.getBool("autoSave") ?? true,
      deleteDuplicates: prefs.getBool("deleteDuplicates") ?? false,
      notifications: prefs.getBool("notifications") ?? true,
      scanDepth: prefs.getString("scanDepth") ?? "Medium",
    ));
  }

  Future<void> _onUpdateSetting(UpdateSetting event, Emitter<SettingsState> emit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(event.key, event.value);

    emit(state.copyWith(
      darkMode: event.key == "darkMode" ? event.value : state.darkMode,
      autoSave: event.key == "autoSave" ? event.value : state.autoSave,
      deleteDuplicates: event.key == "deleteDuplicates" ? event.value : state.deleteDuplicates,
      notifications: event.key == "notifications" ? event.value : state.notifications,
      scanDepth: event.key == "scanDepth" ? event.value : state.scanDepth,
    ));
  }
}
