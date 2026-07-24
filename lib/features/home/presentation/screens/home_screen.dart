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
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';

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
    final horizontalPadding = AppResponsive.pagePadding(context);
    final maxWidth = AppResponsive.maxContentWidth(context);
    final titleScale = AppResponsive.titleScale(context);
    final summaryColumns = AppResponsive.adaptiveColumns(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
    final compactActions = MediaQuery.sizeOf(context).width < 430;

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
    final focusScore = ProductivityAnalyzer.calculateFocusScore(tasks);
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final recommendedTask = ProductivityAnalyzer.getRecommendedTask(tasks);
    final recentTasks = [...tasks]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentNotes = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final hasRecentActivity = recentTasks.isNotEmpty || recentNotes.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: FadeSlideIn(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  100,
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingLabel(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Nuvora',
                    style: AppTypography.displaySmall.copyWith(
                      fontSize: AppTypography.displaySmall.fontSize! * titleScale,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your daily command center',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                        const Text('Today\'s Focus', style: AppTypography.headlineMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${(focusScore * 100).round()}%',
                          style: AppTypography.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          recommendedTask?.title ?? 'No priority task selected yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: focusScore,
                            backgroundColor: AppColors.surfaceSecondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Quick Actions', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  if (compactActions)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
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
                            label: const Text('Create Task'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
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
                            label: const Text('Create Note'),
                          ),
                        ),
                      ],
                    )
                  else
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
                            label: const Text('Create Task'),
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
                            label: const Text('Create Note'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Summary', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    crossAxisCount: summaryColumns,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _SummaryCard(title: 'Tasks', value: '${tasks.length}'),
                      _SummaryCard(title: 'Completed', value: '$completedCount'),
                      _SummaryCard(title: 'Notes', value: '${notes.length}'),
                      _SummaryCard(
                        title: 'Focus',
                        value: '${(focusScore * 100).round()}%',
                      ),
                    ],
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
                    child: hasRecentActivity
                        ? Column(
                            children: [
                              ...recentTasks.take(2).map(
                                (task) => _ActivityRow(
                                  icon: Icons.task_alt,
                                  title: task.title,
                                  subtitle: task.isCompleted
                                      ? 'Completed today: $dueToday due'
                                      : 'Task updated',
                                ),
                              ),
                              ...recentNotes.take(2).map(
                                (note) => _ActivityRow(
                                  icon: Icons.note_alt_outlined,
                                  title: note.title,
                                  subtitle: 'Notes today: $notesToday',
                                ),
                              ),
                            ],
                          )
                        : const _RecentActivityEmptyState(),
                  ),
                ],
                ),
              ),
            ),
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
              color: AppColors.surfaceSecondary,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(value, style: AppTypography.headlineLarge),
        ],
      ),
    );
  }
}

class _RecentActivityEmptyState extends StatelessWidget {
  const _RecentActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.schedule_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No recent activity', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your updates will appear here once you create tasks or notes.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
