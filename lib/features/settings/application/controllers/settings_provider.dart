import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/settings/application/controllers/settings_controller.dart';
import 'package:nuvora/features/settings/domain/entities/user_settings.dart';

final settingsControllerProvider = Provider<SettingsController>((ref) {
	return const SettingsController();
});

final userSettingsProvider = FutureProvider<UserSettings>((ref) async {
	return ref.read(settingsControllerProvider).loadSettings();
});
