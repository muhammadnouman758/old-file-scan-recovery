import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool darkMode;
  final bool autoSave;
  final bool deleteDuplicates;
  final bool notifications;
  final String scanDepth;

  const SettingsState({
    required this.darkMode,
    required this.autoSave,
    required this.deleteDuplicates,
    required this.notifications,
    required this.scanDepth,
  });

  SettingsState copyWith({
    bool? darkMode,
    bool? autoSave,
    bool? deleteDuplicates,
    bool? notifications,
    String? scanDepth,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      autoSave: autoSave ?? this.autoSave,
      deleteDuplicates: deleteDuplicates ?? this.deleteDuplicates,
      notifications: notifications ?? this.notifications,
      scanDepth: scanDepth ?? this.scanDepth,
    );
  }

  @override
  List<Object> get props => [darkMode, autoSave, deleteDuplicates, notifications, scanDepth];
}
