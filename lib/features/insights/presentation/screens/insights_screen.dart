import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider).maybeWhen(
      data: (items) => items,
      orElse: () => <Task>[],
    );
    final notes = ref.watch(notesProvider).maybeWhen(
      data: (items) => items,
      orElse: () => <Note>[],
    );

    final completionRate = ProductivityAnalyzer.calculateCompletionRate(tasks);
    final completed = tasks.where((task) => task.isCompleted).length;
    final score = ProductivityAnalyzer.calculateProductivityScore(tasks, notes);
    final consistency = ProductivityAnalyzer.getConsistencyLevel(score);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = tasks
      .where((task) => task.isCompleted && task.updatedAt.isAfter(weekStart))
      .length;
    final createdNotesThisWeek = notes
      .where((note) => note.createdAt.isAfter(weekStart))
      .length;
    final weeklyProductivity = ((completionRate * 100) * 0.7 + (score * 0.3)).round();
    final streakDays = tasks
      .where((task) => task.isCompleted && _isSameDay(task.updatedAt, now))
      .length;
    final hasAnyData = tasks.isNotEmpty || notes.isNotEmpty;

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
              const Text('Insights', style: AppTypography.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Product performance dashboard built from your current workspace activity',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!hasAnyData)
                _InsightsCard(
                  title: 'Your productivity journey starts here',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.rocket_launch_outlined, color: AppColors.primary),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Create tasks and notes to unlock premium progress insights.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.auto_graph),
                        label: const Text('Generate first insights'),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly productivity',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '$weeklyProductivity / 100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        consistency,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _InsightsCard(
                  title: 'Focus score',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${score.clamp(0, 100)} / 100',
                        style: AppTypography.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 8,
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
                _InsightsCard(
                  title: 'Completion streak',
                  child: _MetricRow(
                    label: 'Active streak today',
                    value: '${streakDays == 0 ? 1 : streakDays} days',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _InsightsCard(
                  title: 'Completed tasks this week',
                  child: Column(
                    children: [
                      _MetricRow(label: 'Completed tasks', value: '$completedThisWeek'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(label: 'Completion rate', value: '${(completionRate * 100).round()}%'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(label: 'Notes captured this week', value: '$createdNotesThisWeek'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(label: 'Total completed tasks', value: '$completed'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title, style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

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
