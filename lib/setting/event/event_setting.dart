import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateSetting extends SettingsEvent {
  final String key;
  final dynamic value;

  UpdateSetting({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
