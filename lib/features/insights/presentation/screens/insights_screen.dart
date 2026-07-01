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
    final pending = tasks.where((task) => !task.isCompleted).length;
    final pinned = notes.where((note) => note.isPinned).length;
    final score = ProductivityAnalyzer.calculateProductivityScore(tasks, notes);
    final consistency = ProductivityAnalyzer.getConsistencyLevel(score);

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
                'Real productivity metrics based on your current data',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                      'Weekly productivity score',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$score / 100',
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
                title: 'Completion rate',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(completionRate * 100).round()}% tasks complete',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: completionRate,
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
                title: 'Real metrics',
                child: Column(
                  children: [
                    _MetricRow(label: 'Completed tasks', value: '$completed'),
                    const SizedBox(height: AppSpacing.sm),
                    _MetricRow(label: 'Pending tasks', value: '$pending'),
                    const SizedBox(height: AppSpacing.sm),
                    _MetricRow(label: 'Notes created', value: '${notes.length}'),
                    const SizedBox(height: AppSpacing.sm),
                    _MetricRow(label: 'Pinned notes', value: '$pinned'),
                  ],
                ),
              ),
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
