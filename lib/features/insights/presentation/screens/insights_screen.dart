import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
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
    final horizontalPadding = AppResponsive.pagePadding(context);
    final maxWidth = AppResponsive.maxContentWidth(context);
    final titleScale = AppResponsive.titleScale(context);
    final productivityColumns = AppResponsive.adaptiveColumns(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

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
    final pending = tasks.length - completed;
    final focusLevel = consistency;
    final totalSignals = tasks.length + notes.length;
    final currentStreakLabel = streakDays == 0 ? '--' : '$streakDays days';
    final bestStreakLabel = completedThisWeek == 0 ? '--' : '$completedThisWeek days';
    final weeklyBars = <double>[
      (completedThisWeek / 7).clamp(0, 1).toDouble(),
      completionRate.clamp(0, 1),
      (score / 100).clamp(0, 1),
      (createdNotesThisWeek / 7).clamp(0, 1).toDouble(),
      (weeklyProductivity / 100).clamp(0, 1).toDouble(),
      (completed / (tasks.isEmpty ? 1 : tasks.length)).clamp(0, 1).toDouble(),
      (notes.length / ((notes.length + tasks.length) == 0 ? 1 : (notes.length + tasks.length))).clamp(0, 1).toDouble(),
    ];

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
                    'Insights',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: AppTypography.displayLarge.fontSize! * titleScale,
                    ),
                  ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A modern snapshot of your execution rhythm and knowledge flow.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedContainer(
                duration: AppMotion.duration,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$totalSignals tracked signals',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!hasAnyData) ...[
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
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _InsightsCard(
                title: 'Productivity Score',
                child: AnimatedSwitcher(
                  duration: AppMotion.duration,
                  child: hasAnyData
                      ? Row(
                          key: const ValueKey('score-data'),
                          children: [
                            _ScoreRing(score: score.clamp(0, 100).toDouble()),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${score.clamp(0, 100)} / 100',
                                    style: AppTypography.headlineLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    consistency,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const _CardPlaceholder(
                          key: ValueKey('score-empty'),
                          message: 'Complete a few tasks to unlock your score trend.',
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InsightsCard(
                title: 'Weekly Overview',
                child: AnimatedSwitcher(
                  duration: AppMotion.duration,
                  child: hasAnyData
                      ? Column(
                          key: const ValueKey('weekly-data'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(weeklyBars.length, (index) {
                                  final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          AnimatedContainer(
                                            duration: AppMotion.duration,
                                            curve: AppMotion.curve,
                                            height: 12 + (weeklyBars[index] * 52),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(
                                                alpha: 0.3 + (weeklyBars[index] * 0.7),
                                              ),
                                              borderRadius: BorderRadius.circular(AppRadius.sm),
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(labels[index], style: AppTypography.labelSmall),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Weekly productivity $weeklyProductivity/100',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : const _CardPlaceholder(
                          key: ValueKey('weekly-empty'),
                          message: 'Your weekly bars will appear after your first activity.',
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InsightsCard(
                title: 'Streak',
                child: productivityColumns == 1
                    ? Column(
                        children: [
                          _MiniMetricCard(
                            label: 'Current streak',
                            value: hasAnyData ? currentStreakLabel : '--',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _MiniMetricCard(
                            label: 'Best streak',
                            value: hasAnyData ? bestStreakLabel : '--',
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _MiniMetricCard(
                              label: 'Current streak',
                              value: hasAnyData ? currentStreakLabel : '--',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _MiniMetricCard(
                              label: 'Best streak',
                              value: hasAnyData ? bestStreakLabel : '--',
                            ),
                          ),
                        ],
                      ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _InsightsCard(
                title: 'Productivity Cards',
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: productivityColumns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                  children: [
                    _MiniMetricCard(label: 'Completed', value: '$completed'),
                    _MiniMetricCard(label: 'Pending', value: '$pending'),
                    _MiniMetricCard(label: 'Notes', value: '${notes.length}'),
                    _MiniMetricCard(
                      label: 'Focus',
                      value: hasAnyData ? focusLevel : '--',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedOpacity(
                duration: AppMotion.duration,
                opacity: hasAnyData ? 1 : 0.92,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insights Summary', style: AppTypography.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      _MetricRow(label: 'Completion rate', value: '${(completionRate * 100).round()}%'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(label: 'Completed this week', value: '$completedThisWeek'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricRow(label: 'Notes this week', value: '$createdNotesThisWeek'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        hasAnyData
                            ? 'Keep your pace by completing one key task before midday.'
                            : 'Start with one task and one note to populate your dashboard.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 7,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Text('${score.round()}', style: AppTypography.labelLarge),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headlineMedium),
        ],
      ),
    );
  }
}
