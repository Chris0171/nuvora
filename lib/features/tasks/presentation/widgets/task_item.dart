import 'package:flutter/material.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_icon_action_button.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskItem extends StatefulWidget {
	const TaskItem({
		super.key,
		required this.task,
		this.categoryName,
		this.onTap,
		this.onDelete,
		this.onToggleCompleted,
	});

	final Task task;
	final String? categoryName;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;
	final ValueChanged<bool>? onToggleCompleted;

	@override
	State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
	bool _pressed = false;

	Color _getPriorityColor() {
		switch (widget.task.priority) {
			case Priority.low:
				return const Color(0xFF60A5FA);
			case Priority.medium:
				return const Color(0xFFF59E0B);
			case Priority.high:
				return const Color(0xFFFB7185);
			case Priority.urgent:
				return const Color(0xFFF43F5E);
		}
	}

	String _getPriorityLabel() {
		return widget.task.priority.name.toUpperCase();
	}

	String _getPriorityExplanation() {
		return ProductivityAnalyzer.getPriorityExplanation(widget.task);
	}

	String _repeatLabel() {
		switch (widget.task.repeatType) {
			case RepeatType.none:
				return 'NO REPEAT';
			case RepeatType.daily:
				return 'DAILY';
			case RepeatType.weekly:
				return 'WEEKLY';
			case RepeatType.monthly:
				return 'MONTHLY';
		}
	}

	String? _formatDueDate() {
		if (widget.task.dueDate == null) return null;
		final now = DateTime.now();
		final date = widget.task.dueDate!;

		if (date.year == now.year &&
				date.month == now.month &&
				date.day == now.day) {
			return 'Today';
		}

		if (date.year == now.year &&
				date.month == now.month &&
				date.day == now.day + 1) {
			return 'Tomorrow';
		}

		return '${date.month}/${date.day}/${date.year}';
	}

	@override
	Widget build(BuildContext context) {
		final dueDate = _formatDueDate();
		final showCategory = widget.categoryName != null && widget.categoryName!.trim().isNotEmpty;
		final showRepeat = widget.task.repeatType != RepeatType.none;
		final showMeta =
			widget.task.priority != Priority.medium || dueDate != null || showCategory || showRepeat;
		final isDue = widget.task.dueDate != null &&
			widget.task.dueDate!.isBefore(DateTime.now()) &&
			!widget.task.isCompleted;
		final completionLabel = widget.task.isCompleted
			? 'Mark ${widget.task.title} as incomplete'
			: 'Mark ${widget.task.title} as completed';
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final shortMotionDuration = AppMotion.resolvedDuration(context, AppMotion.shortDuration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

		return AnimatedScale(
			duration: shortMotionDuration,
			scale: _pressed ? 0.985 : 1,
			curve: motionCurve,
			child: Dismissible(
				key: ValueKey('task-${widget.task.id}'),
				background: const _SwipeBackground(
					icon: Icons.check,
					label: 'Complete',
					color: AppColors.success,
					alignment: Alignment.centerLeft,
				),
				secondaryBackground: const _SwipeBackground(
					icon: Icons.delete_outline,
					label: 'Delete',
					color: AppColors.danger,
					alignment: Alignment.centerRight,
				),
				confirmDismiss: (direction) async {
					if (direction == DismissDirection.startToEnd) {
						widget.onToggleCompleted?.call(!widget.task.isCompleted);
						return false;
					}
					widget.onDelete?.call();
					return false;
				},
				child: AnimatedContainer(
					duration: motionDuration,
					curve: motionCurve,
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(AppRadius.lg),
						boxShadow: [
							BoxShadow(
								color: Colors.black.withValues(alpha: _pressed ? 0.08 : 0.04),
								blurRadius: _pressed ? 16 : 8,
								offset: Offset(0, _pressed ? 8 : 4),
							),
						],
					),
					child: Card(
						elevation: 0,
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(AppRadius.lg),
							side: BorderSide(
								color: isDue
									? AppColors.danger.withValues(alpha: 0.2)
									: AppColors.border,
								width: 1,
							),
						),
						child: AnimatedContainer(
							duration: motionDuration,
							curve: motionCurve,
							decoration: BoxDecoration(
								color: widget.task.isCompleted
									? AppColors.surfaceSecondary
									: AppColors.surface,
								borderRadius: BorderRadius.circular(AppRadius.lg),
							),
							child: InkWell(
								onTap: widget.onTap,
								onTapDown: (_) => setState(() => _pressed = true),
								onTapCancel: () => setState(() => _pressed = false),
								onTapUp: (_) => setState(() => _pressed = false),
								borderRadius: BorderRadius.circular(AppRadius.lg),
								child: Padding(
									padding: const EdgeInsets.all(AppSpacing.md),
									child: Row(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Padding(
												padding: const EdgeInsets.only(
													right: AppSpacing.md,
												),
												child: Stack(
													alignment: Alignment.center,
													children: [
														IgnorePointer(
															child: _AnimatedCheckmark(value: widget.task.isCompleted),
														),
														SizedBox(
															width: 48,
															height: 48,
															child: Opacity(
																opacity: 0.01,
																child: Checkbox(
																	value: widget.task.isCompleted,
																	semanticLabel: completionLabel,
																	materialTapTargetSize: MaterialTapTargetSize.padded,
																	onChanged: (value) {
																		if (value == null) return;
																		widget.onToggleCompleted?.call(value);
																	},
																),
															),
														),
													],
												),
											),
											Expanded(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														AnimatedOpacity(
															duration: AppMotion.duration,
															opacity: widget.task.isCompleted ? 0.8 : 1,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
														Text(
															widget.task.title,
															style: AppTypography.headlineLarge.copyWith(
																decoration: widget.task.isCompleted
																	? TextDecoration.lineThrough
																	: null,
																color: widget.task.isCompleted
																	? AppColors.textTertiary
																	: AppColors.textPrimary,
																height: 1.2,
															),
															maxLines: 2,
															overflow: TextOverflow.ellipsis,
														),
														if (widget.task.description != null) ...[
															const SizedBox(height: AppSpacing.sm),
															Text(
																widget.task.description!,
																style: AppTypography.bodySmall.copyWith(
																	color: widget.task.isCompleted
																		? AppColors.textTertiary
																		: AppColors.textSecondary,
																),
																maxLines: 2,
																overflow: TextOverflow.ellipsis,
															),
														],
														if (showMeta) ...[
															const SizedBox(height: AppSpacing.md),
															Wrap(
																spacing: AppSpacing.sm,
																runSpacing: AppSpacing.xs,
																crossAxisAlignment: WrapCrossAlignment.center,
																children: [
																Container(
																	padding: const EdgeInsets.symmetric(
																		horizontal: AppSpacing.sm,
																		vertical: AppSpacing.xs,
																	),
																	decoration: BoxDecoration(
																		color: _getPriorityColor().withValues(alpha: 0.14),
																		borderRadius: BorderRadius.circular(AppRadius.full),
																	),
																	child: Text(
																		_getPriorityLabel(),
																		style: AppTypography.labelSmall.copyWith(
																			color: _getPriorityColor(),
																			fontWeight: FontWeight.w700,
																		),
																	),
																),
																Text(
																	_getPriorityExplanation(),
																	style: AppTypography.labelSmall.copyWith(
																		color: AppColors.textSecondary,
																	),
																),
																if (showCategory)
																	Container(
																		padding: const EdgeInsets.symmetric(
																			horizontal: AppSpacing.sm,
																			vertical: AppSpacing.xs,
																		),
																		decoration: BoxDecoration(
																			color: AppColors.surfaceSecondary,
																			borderRadius: BorderRadius.circular(AppRadius.full),
																		),
																		child: Text(
																			widget.categoryName!,
																			style: AppTypography.labelSmall.copyWith(
																				color: AppColors.textSecondary,
																			),
																		),
																	),
																if (showRepeat)
																	Container(
																		padding: const EdgeInsets.symmetric(
																			horizontal: AppSpacing.sm,
																			vertical: AppSpacing.xs,
																		),
																		decoration: BoxDecoration(
																			color: AppColors.primaryLight,
																			borderRadius: BorderRadius.circular(AppRadius.full),
																		),
																		child: Text(
																			_repeatLabel(),
																			style: AppTypography.labelSmall.copyWith(
																				color: AppColors.primaryDark,
																			),
																		),
																	),
																if (dueDate != null)
																	Row(
																		mainAxisSize: MainAxisSize.min,
																		children: [
																			Icon(
																				Icons.calendar_today,
																				size: 14,
																				color: isDue
																					? AppColors.danger
																					: AppColors.textSecondary,
																			),
																			const SizedBox(width: AppSpacing.xs),
																			Text(
																				dueDate,
																				style: AppTypography.labelSmall.copyWith(
																					color: isDue
																						? AppColors.danger
																						: AppColors.textSecondary,
																				),
																			),
																		],
																	),
																],
															),
														],
																],
															),
														),
													],
												),
											),
											Padding(
												padding: const EdgeInsets.only(left: AppSpacing.md),
												child: AppIconActionButton(
													icon: Icons.close,
													label: 'Delete task ${widget.task.title}',
													onPressed: widget.onDelete,
												),
											),
										],
									),
								),
							),
						),
					),
				),
			),
		);
	}
}

class _AnimatedCheckmark extends StatelessWidget {
	const _AnimatedCheckmark({required this.value});

	final bool value;

	@override
	Widget build(BuildContext context) {
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final shortMotionDuration = AppMotion.resolvedDuration(context, AppMotion.shortDuration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

		return AnimatedContainer(
			duration: motionDuration,
			curve: motionCurve,
			width: 24,
			height: 24,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: value ? AppColors.primary : Colors.transparent,
				border: Border.all(
					color: value ? AppColors.primary : AppColors.textSecondary,
					width: 1.8,
				),
			),
			child: AnimatedScale(
				duration: shortMotionDuration,
				scale: value ? 1 : 0,
				curve: motionCurve,
				child: const Icon(Icons.check, size: 14, color: Colors.white),
			),
		);
	}
}

class _SwipeBackground extends StatelessWidget {
	const _SwipeBackground({
		required this.icon,
		required this.label,
		required this.color,
		required this.alignment,
	});

	final IconData icon;
	final String label;
	final Color color;
	final Alignment alignment;

	@override
	Widget build(BuildContext context) {
		final isLeft = alignment == Alignment.centerLeft;
		return Container(
			padding: EdgeInsets.only(
				left: isLeft ? AppSpacing.lg : 0,
				right: isLeft ? 0 : AppSpacing.lg,
			),
			alignment: alignment,
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.15),
				borderRadius: BorderRadius.circular(AppRadius.lg),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, color: color),
					const SizedBox(width: AppSpacing.sm),
					Text(
						label,
						style: AppTypography.labelLarge.copyWith(color: color),
					),
				],
			),
		);
	}
}
