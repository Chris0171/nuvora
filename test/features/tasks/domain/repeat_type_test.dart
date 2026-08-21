import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/repeat_type.dart';

void main() {
	test('supports expected repeat values', () {
		expect(
			RepeatType.values,
			equals(<RepeatType>[
				RepeatType.none,
				RepeatType.daily,
				RepeatType.weekly,
				RepeatType.monthly,
			]),
		);
	});

	test('serializes and deserializes by name', () {
		for (final repeatType in RepeatType.values) {
			final serialized = repeatType.name;
			final restored = RepeatType.values.byName(serialized);
			expect(restored, repeatType);
		}
	});
}
