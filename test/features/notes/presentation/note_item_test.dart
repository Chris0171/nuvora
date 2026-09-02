import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/widgets/note_item.dart';

Note _note({
  String id = 'n1',
  String title = 'Title',
  String content = 'Body text',
  bool isPinned = false,
}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026, 6, 15),
      isPinned: isPinned,
    );

Widget _app(Note note, {
  VoidCallback? onTap,
  VoidCallback? onDelete,
  VoidCallback? onTogglePin,
  VoidCallback? onToggleArchive,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NoteItem(
        note: note,
        onTap: onTap,
        onDelete: onDelete,
        onTogglePin: onTogglePin,
        onToggleArchive: onToggleArchive,
      ),
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
    await tester.tap(find.byType(Card));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('calls onDelete', (tester) async {
    bool called = false;
    await tester.pumpWidget(_app(_note(), onDelete: () => called = true));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('shows Pin action when unpinned and calls onTogglePin', (tester) async {
    bool pinCalled = false;
    await tester.pumpWidget(
      _app(_note(title: 'Idea', isPinned: false), onTogglePin: () => pinCalled = true),
    );
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.byTooltip('Pin note Idea'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pump();
    expect(pinCalled, isTrue);
  });

  testWidgets('shows Unpin action when pinned and calls onTogglePin', (tester) async {
    bool unpinCalled = false;
    await tester.pumpWidget(
      _app(_note(title: 'Idea', isPinned: true), onTogglePin: () => unpinCalled = true),
    );
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.byTooltip('Unpin note Idea'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.push_pin));
    await tester.pump();
    expect(unpinCalled, isTrue);
  });

  testWidgets('shows Archive action when active and calls onToggleArchive', (tester) async {
    bool archiveCalled = false;
    await tester.pumpWidget(
      _app(
        _note(title: 'Active Idea').copyWith(archived: false),
        onToggleArchive: () => archiveCalled = true,
      ),
    );
    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    expect(find.byTooltip('Archive note Active Idea'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.archive_outlined));
    await tester.pump();
    expect(archiveCalled, isTrue);
  });

  testWidgets('shows Unarchive action when archived and calls onToggleArchive', (tester) async {
    bool unarchiveCalled = false;
    await tester.pumpWidget(
      _app(
        _note(title: 'Archived Idea').copyWith(archived: true),
        onToggleArchive: () => unarchiveCalled = true,
      ),
    );
    expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);
    expect(find.byTooltip('Unarchive note Archived Idea'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.unarchive_outlined));
    await tester.pump();
    expect(unarchiveCalled, isTrue);
  });
}
