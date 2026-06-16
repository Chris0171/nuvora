import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/presentation/widgets/task_item.dart';

Task _makeTask({
  String id = 'tid',
  String title = 'Test Task',
  String? description,
  bool isCompleted = false,
}) =>
    Task(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime(2026, 6, 14),
      isCompleted: isCompleted,
      priority: Priority.medium,
      repeatType: RepeatType.none,
    );

Widget _buildSubject(
  Task task, {
  VoidCallback? onTap,
  VoidCallback? onDelete,
  ValueChanged<bool>? onToggleCompleted,
}) =>
    MaterialApp(
      home: Scaffold(
        body: TaskItem(
          task: task,
          onTap: onTap,
          onDelete: onDelete,
          onToggleCompleted: onToggleCompleted,
        ),
      ),
    );

void main() {
  group('TaskItem', () {
    testWidgets('renders task title', (tester) async {
      await tester.pumpWidget(_buildSubject(_makeTask(title: 'Buy groceries')));
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('renders description when present', (tester) async {
      await tester.pumpWidget(
        _buildSubject(_makeTask(description: 'Milk, eggs, bread')),
      );
      expect(find.text('Milk, eggs, bread'), findsOneWidget);
    });

    testWidgets('does not render description when null', (tester) async {
      await tester.pumpWidget(_buildSubject(_makeTask(description: null)));
      // Only the title Text should exist inside our custom widget.
      // find.descendant scopes the search to TaskItem's subtree.
      expect(
        find.descendant(
          of: find.byType(TaskItem),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('checkbox is checked when task is completed', (tester) async {
      await tester
          .pumpWidget(_buildSubject(_makeTask(isCompleted: true)));
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('checkbox is unchecked when task is not completed',
        (tester) async {
      await tester
          .pumpWidget(_buildSubject(_makeTask(isCompleted: false)));
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets(
        'calls onToggleCompleted(true) when tapping unchecked checkbox',
        (tester) async {
      bool? received;
      await tester.pumpWidget(
        _buildSubject(
          _makeTask(isCompleted: false),
          onToggleCompleted: (v) => received = v,
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(received, isTrue);
    });

    testWidgets(
        'calls onToggleCompleted(false) when tapping checked checkbox',
        (tester) async {
      bool? received;
      await tester.pumpWidget(
        _buildSubject(
          _makeTask(isCompleted: true),
          onToggleCompleted: (v) => received = v,
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(received, isFalse);
    });

    testWidgets('calls onDelete when delete icon button tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _buildSubject(_makeTask(), onDelete: () => called = true),
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('calls onTap when tile body tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _buildSubject(_makeTask(), onTap: () => called = true),
      );
      await tester.tap(find.byType(Card));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('delete button is visible', (tester) async {
      await tester.pumpWidget(_buildSubject(_makeTask()));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
