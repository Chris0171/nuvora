import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/app_page_route.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/presentation/screens/create_task_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greetingLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final notesAsync = ref.watch(notesProvider);
    final tasks = tasksAsync.maybeWhen(
      data: (items) => items,
      orElse: () => <Task>[],
    );
    final notes = notesAsync.maybeWhen(
      data: (items) => items,
      orElse: () => <Note>[],
    );
    final now = DateTime.now();

    final dueToday = tasks
      .where((task) => task.dueDate != null && _isSameDay(task.dueDate!, now))
      .length;
    final notesToday = notes.where((note) => _isSameDay(note.createdAt, now)).length;
    final completionRate = ProductivityAnalyzer.calculateCompletionRate(tasks);
    final recommendedTask = ProductivityAnalyzer.getRecommendedTask(tasks);
    final focusScore = ProductivityAnalyzer.calculateFocusScore(tasks);
    final recentTasks = [...tasks]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentNotes = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingLabel()}, Christian',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Nuvora dashboard', style: AppTypography.displaySmall),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Focus Score',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${(focusScore * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: focusScore,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today summary', style: AppTypography.headlineMedium),
                    const SizedBox(height: AppSpacing.md),
                    _OverviewRow(label: 'Tasks due today', value: '$dueToday'),
                    const SizedBox(height: AppSpacing.sm),
                    _OverviewRow(label: 'Notes created', value: '$notesToday'),
                    const SizedBox(height: AppSpacing.sm),
                    _OverviewRow(
                      label: 'Productivity percentage',
                      value: '${(completionRate * 100).round()}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: recommendedTask == null
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('You should do next', style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No pending tasks right now. Great work.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('You should do next', style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(recommendedTask.title, style: AppTypography.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ProductivityAnalyzer.getRecommendedUrgencyText(recommendedTask),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Recent activity', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ...recentTasks.take(2).map(
                      (task) => _ActivityRow(
                        icon: Icons.task_alt,
                        title: task.title,
                        subtitle: task.isCompleted ? 'Task completed' : 'Task updated',
                      ),
                    ),
                    ...recentNotes.take(2).map(
                      (note) => _ActivityRow(
                        icon: Icons.note_alt_outlined,
                        title: note.title,
                        subtitle: 'Note updated',
                      ),
                    ),
                    if (recentTasks.isEmpty && recentNotes.isEmpty)
                      const _ActivityRow(
                        icon: Icons.auto_awesome,
                        title: 'No activity yet',
                        subtitle: 'Create your first task or note to get started.',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Quick actions', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          AppPageRoute<void>(
                            builder: (_) => const CreateTaskScreen(),
                          ),
                        );
                        ref.invalidate(tasksProvider);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          AppPageRoute<void>(
                            builder: (_) => const CreateNoteScreen(),
                          ),
                        );
                        ref.invalidate(notesProvider);
                      },
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('Add Note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(value, style: AppTypography.labelLarge),
      ],
    );
  }
}
