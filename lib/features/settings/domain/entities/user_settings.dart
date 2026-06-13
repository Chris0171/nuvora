class UserSettings {
	const UserSettings({
		required this.darkMode,
		required this.notificationsEnabled,
		required this.language,
	});

	final bool darkMode;
	final bool notificationsEnabled;
	final String language;
}
