import 'package:nuvora/core/constants/reminder_type.dart';

class Reminder {
	const Reminder({
		required this.id,
		required this.scheduledTime,
		required this.relatedItemId,
		required this.type,
		required this.enabled,
	});

	final String id;
	final DateTime scheduledTime;
	final String relatedItemId;
	final ReminderType type;
	final bool enabled;
}
