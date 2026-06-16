import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/widgets/note_item.dart';

Note _note({
  String id = 'n1',
  String title = 'Title',
  String content = 'Body text',
}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: false,
    );

Widget _app(Note note, {VoidCallback? onTap, VoidCallback? onDelete}) {
  return MaterialApp(
    home: Scaffold(
      body: NoteItem(note: note, onTap: onTap, onDelete: onDelete),
    ),
  );
}

void main() {
  testWidgets('renders title and content', (tester) async {
    await tester.pumpWidget(_app(_note(title: 'A', content: 'B')));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('calls onTap', (tester) async {
    bool called = false;
    await tester.pumpWidget(_app(_note(), onTap: () => called = true));
    await tester.tap(find.byType(ListTile));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('calls onDelete', (tester) async {
    bool called = false;
    await tester.pumpWidget(_app(_note(), onDelete: () => called = true));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(called, isTrue);
  });
}
